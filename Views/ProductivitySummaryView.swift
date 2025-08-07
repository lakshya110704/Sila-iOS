//
//  ProductivitySummaryView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI
import CoreData
import Charts

struct DailyStudyData: Identifiable {
    var id: Date { date }
    let date: Date
    let totalMinutes: Int
}

struct ProductivitySummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudyTask.date, ascending: false)],
        predicate: NSPredicate(format: "completed == true"),
        animation: .default
    )
    private var completedTasks: FetchedResults<StudyTask>

    private var todayTotalMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let filtered = completedTasks.filter {
            guard let date = $0.date else { return false }
            return Calendar.current.isDate(date, inSameDayAs: today)
        }
        return filtered.reduce(0) { $0 + Int($1.duration) }
    }
    
    private var past7DaysData: [DailyStudyData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let total = completedTasks
                .filter { task in
                    guard let taskDate = task.date else { return false }
                    return calendar.isDate(taskDate, inSameDayAs: date)
                }
                .reduce(0) { $0 + Int($1.duration) }
            
            return DailyStudyData(date: date, totalMinutes: total)
        }
        .reversed() // Oldest to newest
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("📈 Today’s Total Study Time")
                    .font(.headline)
                Text("\(todayTotalMinutes) minutes")
                    .font(.largeTitle)
                    .bold()

                Divider()

                Text("✅ Completed Tasks")
                    .font(.headline)

                List {
                    ForEach(completedTasks) { task in
                        VStack(alignment: .leading) {
                            Text(task.title ?? "")
                                .font(.headline)
                            Text(task.subject ?? "")
                                .font(.subheadline)
                        }
                    }
                }
                
                Text("📅 Weekly Study Chart")
                    .font(.headline)

                Chart {
                    ForEach(past7DaysData) { data in
                        BarMark(
                            x: .value("Day", data.date, unit: .day),
                            y: .value("Minutes", data.totalMinutes)
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.narrow)) // M, T, W...
                    }
                }
                .frame(height: 200)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Summary")
        }
    }
}
