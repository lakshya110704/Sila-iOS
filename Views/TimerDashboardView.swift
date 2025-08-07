//
//  TimerDashboardView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI

struct TimerDashboardView: View {
    enum TimerMode: String, CaseIterable {
        case pomodoro = "Pomodoro"
        case deepWork = "Deep Work"
        case breakMode = "Break"
    }

    @State private var selectedMode: TimerMode = .pomodoro
    @State private var timeRemaining: Int = 1500 // 25 mins default
    @State private var isRunning = false
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
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
            .onChange(of: selectedMode) { _ in
                resetTimer()
            }
            .navigationTitle("Focus Timer")
        }
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startTimer() {
        setDuration(for: selectedMode)
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                isRunning = false
                timer?.invalidate()
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
    }

    private func resetTimer() {
        isRunning = false
        timer?.invalidate()
        setDuration(for: selectedMode)
    }

    private func setDuration(for mode: TimerMode) {
        switch mode {
        case .pomodoro:
            timeRemaining = 1500 // 25 min
        case .deepWork:
            timeRemaining = 3600 // 60 min
        case .breakMode:
            timeRemaining = 600 // 10 min
        }
    }
}