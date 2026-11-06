//
//  PlannerWeek.swift
//  Sila
//

import Foundation

struct PlannerDay: Identifiable {
    var id: Date { date }
    let date: Date
    let tasks: [StudyTask]
}

enum PlannerWeek {
    static func start(of date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)!.start
    }

    /// The 7 days from weekStart, each with its tasks in the order given.
    /// shortcut: a task with no date appears in no week, but AddTaskView always sets one.
    static func days(from weekStart: Date, tasks: [StudyTask], calendar: Calendar = .current) -> [PlannerDay] {
        (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let tasksThatDay = tasks.filter { task in
                guard let date = task.date else { return false }
                return calendar.isDate(date, inSameDayAs: day)
            }
            return PlannerDay(date: day, tasks: tasksThatDay)
        }
    }
}
