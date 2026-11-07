//
//  TimerViewModel.swift
//  Sila
//

import Foundation
import UserNotifications

enum TimerMode: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case breakMode = "Break"

    var seconds: Int {
        switch self {
        case .pomodoro: return 25 * 60
        case .deepWork: return 90 * 60
        case .breakMode: return 5 * 60
        }
    }
}

/// Drives the countdown. Injected so tests can run it without real time passing.
struct TimerClock {
    var now: () -> Date
    /// Seconds since boot. Keeps counting while the device sleeps, and changing the device clock doesn't move it.
    var uptime: () -> TimeInterval
    /// Different after every reboot, which is when uptime starts again from zero.
    var bootID: () -> String
    /// Calls the handler once a second and returns a closure that stops it.
    var scheduleTicks: (@escaping () -> Void) -> () -> Void

    static let system = TimerClock(
        now: Date.init,
        uptime: { TimeInterval(clock_gettime_nsec_np(CLOCK_MONOTONIC)) / 1_000_000_000 },
        bootID: {
            var size = 0
            sysctlbyname("kern.bootsessionuuid", nil, &size, nil, 0)
            var buffer = [CChar](repeating: 0, count: size)
            sysctlbyname("kern.bootsessionuuid", &buffer, &size, nil, 0)
            return String(cString: buffer)
        },
        scheduleTicks: { handler in
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in handler() }
            return { timer.invalidate() }
        }
    )
}

/// Tells the user when a timer finishes. Injected so tests don't touch the real notification center.
struct TimerNotifier {
    var scheduleFinish: (_ mode: TimerMode, _ secondsFromNow: Int) -> Void
    var cancelFinish: () -> Void

    private static let requestID = "timer.finished"

    static let system = TimerNotifier(
        scheduleFinish: { mode, seconds in
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in
                let content = UNMutableNotificationContent()
                content.title = "\(mode.rawValue) finished"
                content.body = "Your timer is done."
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
                center.add(UNNotificationRequest(identifier: requestID, content: content, trigger: trigger))
            }
        },
        cancelFinish: {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestID])
        }
    )
}

/// Shows the notification as a banner when the app is already open, which iOS doesn't do by default.
final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

final class TimerViewModel: ObservableObject {
    @Published var mode: TimerMode = .pomodoro {
        didSet {
            if mode != oldValue { reset() }
        }
    }
    @Published private(set) var timeRemaining = TimerMode.pomodoro.seconds
    @Published private(set) var isRunning = false
    @Published private(set) var focusTaskURL: URL?
    @Published private var sessionStart: Date?

    private let clock: TimerClock
    private let defaults: UserDefaults
    private let notifier: TimerNotifier
    private let onSessionEnd: (_ mode: TimerMode, _ startedAt: Date, _ endedAt: Date, _ finished: Bool, _ focusedSeconds: Int, _ taskURL: URL?) -> Void
    private var sessionMode: TimerMode?
    private var stopTicks: (() -> Void)?
    private var endDate: Date?
    private var endUptime: TimeInterval?

    private enum Key {
        static let mode = "timer.mode"
        static let timeRemaining = "timer.timeRemaining"
        static let endDate = "timer.endDate"
        static let endUptime = "timer.endUptime"
        static let bootID = "timer.bootID"
        static let sessionStart = "timer.sessionStart"
        static let sessionMode = "timer.sessionMode"
        static let focusTask = "timer.focusTask"
    }

    init(
        clock: TimerClock = .system,
        defaults: UserDefaults = .standard,
        notifier: TimerNotifier = .system,
        onSessionEnd: @escaping (TimerMode, Date, Date, Bool, Int, URL?) -> Void = { _, _, _, _, _, _ in }
    ) {
        self.clock = clock
        self.defaults = defaults
        self.notifier = notifier
        self.onSessionEnd = onSessionEnd

        guard let saved = defaults.string(forKey: Key.mode).flatMap(TimerMode.init(rawValue:)) else { return }
        // Set through the wrapper because mode's didSet would reset the saved state.
        _mode = Published(initialValue: saved)
        timeRemaining = defaults.integer(forKey: Key.timeRemaining)
        focusTaskURL = defaults.url(forKey: Key.focusTask)
        sessionStart = defaults.object(forKey: Key.sessionStart) as? Date
        sessionMode = defaults.string(forKey: Key.sessionMode).flatMap(TimerMode.init(rawValue:))
        if let savedEnd = defaults.object(forKey: Key.endDate) as? Date {
            endDate = savedEnd
            // Uptime only means something within one boot, so after a reboot go by the device clock.
            if defaults.string(forKey: Key.bootID) == clock.bootID(),
               let savedEndUptime = defaults.object(forKey: Key.endUptime) as? TimeInterval {
                endUptime = savedEndUptime
            } else {
                endUptime = clock.uptime() + savedEnd.timeIntervalSince(clock.now())
            }
            isRunning = true
            scheduleTicks()
            refresh()
        }
    }

    var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    var hasActiveSession: Bool {
        sessionStart != nil
    }

    /// Attaches a task to the next session. A session in progress keeps the task it started with.
    func focus(on taskURL: URL?) {
        guard !hasActiveSession else { return }
        if taskURL != nil && mode == .breakMode { mode = .pomodoro }
        focusTaskURL = taskURL
        save()
    }

    func start() {
        if timeRemaining == 0 { timeRemaining = mode.seconds }
        isRunning = true
        if sessionStart == nil {
            sessionStart = clock.now()
            sessionMode = mode
        }
        endDate = clock.now().addingTimeInterval(TimeInterval(timeRemaining))
        endUptime = clock.uptime() + TimeInterval(timeRemaining)
        scheduleTicks()
        notifier.scheduleFinish(mode, timeRemaining)
        save()
    }

    func pause() {
        refresh()
        stop()
        notifier.cancelFinish()
        save()
    }

    func reset() {
        refresh()
        // Under a minute is more likely a mistaken tap than a session given up on.
        if let sessionStart, clock.now().timeIntervalSince(sessionStart) >= 60 {
            endSession(finished: false, endedAt: clock.now())
        }
        sessionStart = nil
        sessionMode = nil
        stop()
        notifier.cancelFinish()
        timeRemaining = mode.seconds
        save()
    }

    /// Recomputes from the end time, because ticks don't fire while the app is suspended.
    /// shortcut: a device clock change made around a reboot still shifts a running timer, store elapsed time if that matters.
    func refresh() {
        guard isRunning, let endUptime else { return }
        timeRemaining = max(0, Int((endUptime - clock.uptime()).rounded(.up)))
        if timeRemaining == 0 {
            endSession(finished: true, endedAt: self.endDate ?? clock.now())
            sessionStart = nil
            sessionMode = nil
            stop()
            save()
        }
    }

    private func endSession(finished: Bool, endedAt: Date) {
        guard let sessionStart, let sessionMode else { return }
        onSessionEnd(sessionMode, sessionStart, endedAt, finished, sessionMode.seconds - timeRemaining,
                     sessionMode == .breakMode ? nil : focusTaskURL)
    }

    private func scheduleTicks() {
        stopTicks?()
        stopTicks = clock.scheduleTicks { [weak self] in self?.refresh() }
    }

    private func stop() {
        isRunning = false
        endDate = nil
        endUptime = nil
        stopTicks?()
        stopTicks = nil
    }

    // Saved on every state change, not on backgrounding, because iOS can terminate the app without warning.
    private func save() {
        defaults.set(mode.rawValue, forKey: Key.mode)
        defaults.set(timeRemaining, forKey: Key.timeRemaining)
        defaults.set(endDate, forKey: Key.endDate)
        defaults.set(endUptime, forKey: Key.endUptime)
        defaults.set(clock.bootID(), forKey: Key.bootID)
        defaults.set(sessionStart, forKey: Key.sessionStart)
        defaults.set(sessionMode?.rawValue, forKey: Key.sessionMode)
        defaults.set(focusTaskURL, forKey: Key.focusTask)
    }
}
