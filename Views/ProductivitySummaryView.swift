//
//  ProductivitySummaryView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI
import CoreData
import Charts

struct ProductivitySummaryView: View {
    @StateObject private var viewModel: ProductivitySummaryViewModel
    @Environment(\.dynamicTypeSize) private var typeSize
    private var completedRowLayout: AnyLayout { typeSize.stack(alignment: .leading) }

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ProductivitySummaryViewModel(context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitle(text: "Summary")
            List {
                Section {
                    Text("^[\(viewModel.todayTotalMinutes) minute](inflect: true)")
                        .font(.serif(.largeTitle, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityIdentifier("todayFocusTime")
                        .listRowBackground(Color.card)
                } header: {
                    SectionTitle(text: "Today’s Focus Time")
                }

                Section {
                    if viewModel.past7DaysData.allSatisfy({ $0.totalMinutes == 0 }) {
                        Text("No focus time this week. Finish or reset a Pomodoro or Deep Work session to see it here.")
                            .foregroundColor(.muted)
                            .listRowBackground(Color.card)
                    } else {
                        Chart {
                            ForEach(viewModel.past7DaysData) { data in
                                BarMark(
                                    x: .value("Day", data.date, unit: .day),
                                    y: .value("Minutes", data.totalMinutes)
                                )
                                .cornerRadius(5)
                                .foregroundStyle(Color.accentColor)
                            }
                        }
                        .chartXAxis {
                            // Only the 7 days, so there's no extra gridline at the end of today.
                            AxisMarks(values: viewModel.past7DaysData.map(\.date)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.weekday(.narrow)) // M, T, W...
                            }
                        }
                        .frame(height: 200)
                        .listRowBackground(Color.card)
                    }
                } header: {
                    SectionTitle(text: "Weekly Focus Time")
                }

                Section {
                    if viewModel.completedTasks.isEmpty {
                        Text("Nothing completed yet.")
                            .foregroundColor(.muted)
                            .listRowBackground(Color.card)
                    }
                    ForEach(viewModel.completedTasks) { task in
                        completedRowLayout {
                            VStack(alignment: .leading) {
                                Text(task.title ?? "Untitled")
                                    .font(.headline)
                                Text(task.subject ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.muted)
                            }
                            if !typeSize.isAccessibilitySize {
                                Spacer()
                            }
                            Text(task.durationLabel)
                                .foregroundColor(.muted)
                        }
                        .listRowBackground(Color.card)
                    }
                } header: {
                    SectionTitle(text: "Completed Tasks")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color.paper)
    }
}
