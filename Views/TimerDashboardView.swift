//
//  TimerDashboardView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI
import CoreData

struct TimerDashboardView: View {
    @StateObject private var viewModel: TimerViewModel
    @StateObject private var suggestions: SuggestionsViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TimerViewModel(onSessionEnd: { mode, startedAt, endedAt, finished in
            TimerSession.record(mode: mode, startedAt: startedAt, endedAt: endedAt, finished: finished, in: context)
        }))
        _suggestions = StateObject(wrappedValue: SuggestionsViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
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
                        .buttonStyle(.borderedProminent)

                        Button("Reset") {
                            viewModel.reset()
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.title2)
                    .controlSize(.large)

                    HStack(alignment: .top, spacing: 12) {
                        suggestionCard(title: "General", id: "general", suggestion: suggestions.general, fallback: "")
                        suggestionCard(title: "Your History", id: "history", suggestion: suggestions.personal,
                                       fallback: suggestions.personalProgress)
                    }
                    .padding(.horizontal)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { viewModel.refresh() }
            }
            .navigationTitle("Focus Timer")
        }
    }

    private func suggestionCard(title: String, id: String, suggestion: Suggestion?, fallback: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            if let suggestion {
                Text(suggestion.mode.rawValue)
                    .font(.headline)
                    .accessibilityIdentifier("\(id)SuggestionMode")
                Text(suggestion.reason)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Use \(suggestion.mode.rawValue)") {
                    viewModel.mode = suggestion.mode
                }
                .font(.footnote)
                .frame(minHeight: 44)
                .disabled(viewModel.isRunning || viewModel.mode == suggestion.mode)
                .accessibilityIdentifier("\(id)SuggestionUse")
            } else {
                Text("Still learning")
                    .font(.headline)
                Text(fallback)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(id)SuggestionProgress")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
