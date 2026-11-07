//
//  TimerDashboardView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI
import CoreData

struct TimerDashboardView: View {
    @ObservedObject var viewModel: TimerViewModel
    @StateObject private var suggestions: SuggestionsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    private var buttonLayout: AnyLayout { typeSize.stack(spacing: 16) }
    private var cardLayout: AnyLayout { typeSize.stack(spacing: 12) }
    // Grows with the text size setting, and minimumScaleFactor keeps it inside the ring.
    @ScaledMetric(relativeTo: .largeTitle) private var timeSize = 60.0
    @FetchRequest(sortDescriptors: []) private var tasks: FetchedResults<StudyTask>

    private var focusTask: StudyTask? {
        guard viewModel.mode != .breakMode else { return nil }
        return tasks.first { $0.objectID.uriRepresentation() == viewModel.focusTaskURL }
    }

    init(context: NSManagedObjectContext, viewModel: TimerViewModel) {
        self.viewModel = viewModel
        _suggestions = StateObject(wrappedValue: SuggestionsViewModel(context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitle(text: "Focus Timer")
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Mode", selection: $viewModel.mode) {
                        ForEach(TimerMode.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])

                    if let focusTask {
                        HStack {
                            Image(systemName: "scope")
                                .foregroundStyle(Color.accentColor)
                                .accessibilityHidden(true)
                            Text(focusTask.title ?? "Untitled")
                                .font(.serif(.headline))
                                .lineLimit(1)
                                .accessibilityIdentifier("focusTaskTitle")
                            if !viewModel.hasActiveSession {
                                Button {
                                    viewModel.focus(on: nil)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Stop focusing on this task")
                            }
                        }
                        .frame(minHeight: 44)
                        .padding(.horizontal)
                    }

                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.18), lineWidth: 14)
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.timeRemaining) / CGFloat(viewModel.mode.seconds))
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(viewModel.timeString)
                            .font(.system(size: timeSize, weight: .semibold, design: .serif))
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, 28)
                            .accessibilityIdentifier("timeRemaining")
                    }
                    .frame(width: 260, height: 260)
                    .padding(.vertical, 8)

                    buttonLayout {
                        Button(viewModel.isRunning ? "Pause" : "Start") {
                            viewModel.isRunning ? viewModel.pause() : viewModel.start()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Color.paper)

                        Button("Reset") {
                            viewModel.reset()
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.serif(.title3))
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)

                    cardLayout {
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
        }
        .background(Color.paper)
    }

    private func suggestionCard(title: String, id: String, suggestion: Suggestion?, fallback: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.muted)
            if let suggestion {
                Text(suggestion.mode.rawValue)
                    .font(.serif(.headline))
                    .accessibilityIdentifier("\(id)SuggestionMode")
                Text(suggestion.reason)
                    .font(.footnote)
                    .foregroundColor(.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    viewModel.mode = suggestion.mode
                } label: {
                    // Inside the label, so the whole 44pt is tappable.
                    Text("Use \(suggestion.mode.rawValue)")
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .font(.footnote)
                .disabled(viewModel.isRunning || viewModel.mode == suggestion.mode)
                .accessibilityIdentifier("\(id)SuggestionUse")
            } else {
                Text("Still learning")
                    .font(.serif(.headline))
                Text(fallback)
                    .font(.footnote)
                    .foregroundColor(.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(id)SuggestionProgress")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
