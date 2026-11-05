//
//  TimerDashboardView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI

enum TimerMode: String, CaseIterable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case breakMode = "Break"

    /// Focus lengths match the README: Pomodoro 25/5, Deep Work 90/20.
    var seconds: Int {
        switch self {
        case .pomodoro: return 25 * 60
        case .deepWork: return 90 * 60
        case .breakMode: return 5 * 60
        }
    }
}

struct TimerDashboardView: View {
    @State private var selectedMode: TimerMode = .pomodoro
    @State private var timeRemaining: Int = TimerMode.pomodoro.seconds
    @State private var isRunning = false
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(TimerMode.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .padding()

                HStack(spacing: 40) {
                    Button(isRunning ? "Pause" : "Start") {
                        isRunning ? pauseTimer() : startTimer()
                    }
                    .font(.title2)

                    Button("Reset") {
                        resetTimer()
                    }
                    .font(.title2)
                }
            }
            .onChange(of: selectedMode) {
                resetTimer()
            }
            .onDisappear(perform: pauseTimer)
            .navigationTitle("Focus Timer")
        }
    }

    private var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    private func startTimer() {
        if timeRemaining == 0 { timeRemaining = selectedMode.seconds }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
            if timeRemaining == 0 {
                pauseTimer()
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        timeRemaining = selectedMode.seconds
    }
}
