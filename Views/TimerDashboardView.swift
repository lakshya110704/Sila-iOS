//
//  TimerDashboardView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI

struct TimerDashboardView: View {
    @StateObject private var viewModel = TimerViewModel()

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
            .onDisappear(perform: viewModel.pause)
            .navigationTitle("Focus Timer")
        }
    }
}
