//
//  TimerDashboardView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI

struct TimerDashboardView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(TimerMode.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Text(viewModel.timeString)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .accessibilityIdentifier("timeRemaining")
                    .padding()

                HStack(spacing: 40) {
                    Button(viewModel.isRunning ? "Pause" : "Start") {
                        viewModel.isRunning ? viewModel.pause() : viewModel.start()
                    }
                    .font(.title2)

                    Button("Reset") {
                        viewModel.reset()
                    }
                    .font(.title2)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { viewModel.refresh() }
            }
            .navigationTitle("Focus Timer")
        }
    }
}
