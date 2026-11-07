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

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ProductivitySummaryViewModel(context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitle(text: "Summary")
            List {
                Section {
                    Text("\(viewModel.todayTotalMinutes) minutes")
                        .font(.serif(.largeTitle, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .listRowBackground(Color.card)
                } header: {
                    SectionTitle(text: "Today’s Total Study Time")
                }

                Section {
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
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.weekday(.narrow)) // M, T, W...
                        }
                    }
                    .frame(height: 200)
                    .listRowBackground(Color.card)
                } header: {
                    SectionTitle(text: "Weekly Study Chart")
                }

                Section {
                    if viewModel.completedTasks.isEmpty {
                        Text("Nothing completed yet.")
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.card)
                    }
                    ForEach(viewModel.completedTasks) { task in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.title ?? "Untitled")
                                    .font(.headline)
                                Text(task.subject ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(task.duration) min")
                                .foregroundColor(.secondary)
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
