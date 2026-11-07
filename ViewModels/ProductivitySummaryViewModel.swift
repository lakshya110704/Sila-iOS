//
//  ProductivitySummaryViewModel.swift
//  Sila
//

import Combine
import CoreData

struct DailyStudyData: Identifiable {
    var id: Date { date }
    let date: Date
    let totalMinutes: Int
}

final class ProductivitySummaryViewModel: ObservableObject {
    @Published private(set) var completedTasks: [StudyTask] = []
    @Published private var sessions: [TimerSession] = []

    private let context: NSManagedObjectContext
    private let now: () -> Date
    private var saveObserver: AnyCancellable?

    init(context: NSManagedObjectContext, now: @escaping () -> Date = Date.init) {
        self.context = context
        self.now = now
        reload()
        saveObserver = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: context)
            .sink { [weak self] _ in self?.reload() }
    }

    var todayTotalMinutes: Int {
        totalMinutes(on: now())
    }

    /// The last 7 days including today, oldest first.
    var past7DaysData: [DailyStudyData] {
        let today = Calendar.current.startOfDay(for: now())
        return (0..<7).reversed().map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: today)!
            return DailyStudyData(date: date, totalMinutes: totalMinutes(on: date))
        }
    }

    private func totalMinutes(on day: Date) -> Int {
        sessions
            .filter { session in
                guard session.isFocus, let endedAt = session.endedAt else { return false }
                return Calendar.current.isDate(endedAt, inSameDayAs: day)
            }
            .reduce(0) { $0 + $1.countedSeconds } / 60
    }

    private func reload() {
        let request = StudyTask.fetchRequest()
        request.predicate = NSPredicate(format: "completed == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudyTask.date, ascending: false)]
        completedTasks = (try? context.fetch(request)) ?? []
        sessions = (try? context.fetch(NSFetchRequest<TimerSession>(entityName: "TimerSession"))) ?? []
    }
}
