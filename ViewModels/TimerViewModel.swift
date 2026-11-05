//
//  TimerViewModel.swift
//  Sila
//

import Foundation

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
    /// Calls the handler once a second and returns a closure that stops it.
    var scheduleTicks: (@escaping () -> Void) -> () -> Void

    static let system = TimerClock(now: Date.init) { handler in
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in handler() }
        return { timer.invalidate() }
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

    private let clock: TimerClock
    private var stopTicks: (() -> Void)?
    private var endDate: Date?

    init(clock: TimerClock = .system) {
        self.clock = clock
    }

    var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    func start() {
        if timeRemaining == 0 { timeRemaining = mode.seconds }
        isRunning = true
        endDate = clock.now().addingTimeInterval(TimeInterval(timeRemaining))
        stopTicks?()
        stopTicks = clock.scheduleTicks { [weak self] in self?.refresh() }
    }

    func pause() {
        refresh()
        stop()
    }

    func reset() {
        stop()
        timeRemaining = mode.seconds
    }

    /// Recomputes from the end date, because ticks don't fire while the app is suspended.
    /// shortcut: changing the device clock shifts the countdown, use a monotonic clock if that matters.
    func refresh() {
        guard isRunning, let endDate else { return }
        timeRemaining = max(0, Int(endDate.timeIntervalSince(clock.now()).rounded(.up)))
        if timeRemaining == 0 {
            stop()
        }
    }

    private func stop() {
        isRunning = false
        endDate = nil
        stopTicks?()
        stopTicks = nil
    }
}
