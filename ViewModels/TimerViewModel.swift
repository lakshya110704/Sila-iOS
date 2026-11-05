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
    /// Calls the handler once a second and returns a closure that stops it.
    var scheduleTicks: (@escaping () -> Void) -> () -> Void

    static let system = TimerClock { handler in
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

    init(clock: TimerClock = .system) {
        self.clock = clock
    }

    var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    func start() {
        if timeRemaining == 0 { timeRemaining = mode.seconds }
        isRunning = true
        stopTicks?()
        stopTicks = clock.scheduleTicks { [weak self] in self?.tick() }
    }

    func pause() {
        isRunning = false
        stopTicks?()
        stopTicks = nil
    }

    func reset() {
        pause()
        timeRemaining = mode.seconds
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        if timeRemaining == 0 {
            pause()
        }
    }
}
