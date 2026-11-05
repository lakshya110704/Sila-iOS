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
        NavigationStack {
            List {
                Section("📈 Today’s Total Study Time") {
                    Text("\(viewModel.todayTotalMinutes) minutes")
                        .font(.largeTitle)
                        .bold()
                }

                Section("📅 Weekly Study Chart") {
                    Chart {
                        ForEach(viewModel.past7DaysData) { data in
                            BarMark(
                                x: .value("Day", data.date, unit: .day),
                                y: .value("Minutes", data.totalMinutes)
                            )
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.weekday(.narrow)) // M, T, W...
                        }
                    }
                    .frame(height: 200)
                }

                Section("✅ Completed Tasks") {
                    if viewModel.completedTasks.isEmpty {
                        Text("Nothing completed yet.")
                            .foregroundColor(.secondary)
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
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
}
