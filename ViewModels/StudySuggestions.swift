//
//  StudySuggestions.swift
//  Sila
//

import Combine
import CoreData

struct Suggestion: Equatable {
    let mode: TimerMode
    let reason: String
}

/// A timer session as the suggestion rules see it.
struct SessionRecord {
    let mode: TimerMode
    let startedAt: Date
    let endedAt: Date
    let finished: Bool
}

enum PartOfDay: String {
    case morning, afternoon, evening, night

    init(hour: Int) {
        switch hour {
        case 5..<12: self = .morning
        case 12..<18: self = .afternoon
        case 18..<22: self = .evening
        default: self = .night
        }
    }
}

enum StudySuggestions {
    /// Sessions needed in a part of the day before history makes a suggestion.
    static let sessionsNeeded = 5
    private static let recentFocus: TimeInterval = 30 * 60
    private static let minimumAttempts = 2

    /// Fixed rules of thumb that work with no history.
    static func general(sessions: [SessionRecord], now: Date) -> Suggestion {
        let justFocused = sessions.contains { session in
            session.finished && session.mode != .breakMode
                && session.endedAt <= now && now.timeIntervalSince(session.endedAt) < recentFocus
        }
        if justFocused {
            return Suggestion(mode: .breakMode, reason: "You just finished a focus session.")
        }
        switch PartOfDay(hour: Calendar.current.component(.hour, from: now)) {
        case .morning:
            return Suggestion(mode: .deepWork, reason: "Mornings are a common time for long focus.")
        case .afternoon, .evening:
            return Suggestion(mode: .pomodoro, reason: "Short sessions are easy to fit in later in the day.")
        case .night:
            return Suggestion(mode: .breakMode, reason: "It's late, so keep it short.")
        }
    }

    /// The focus sessions counted for this part of the day.
    static func focusSessions(_ sessions: [SessionRecord], in part: PartOfDay) -> [SessionRecord] {
        sessions.filter { session in
            session.mode != .breakMode
                && PartOfDay(hour: Calendar.current.component(.hour, from: session.startedAt)) == part
        }
    }

    /// The focus mode you finish most reliably at this time of day, or nil until there's enough history.
    static func personal(sessions: [SessionRecord], now: Date) -> Suggestion? {
        let part = PartOfDay(hour: Calendar.current.component(.hour, from: now))
        let counted = focusSessions(sessions, in: part)
        guard counted.count >= sessionsNeeded else { return nil }

        let results = [TimerMode.pomodoro, .deepWork].compactMap { mode -> (mode: TimerMode, finished: Int, total: Int)? in
            let attempts = counted.filter { $0.mode == mode }
            guard attempts.count >= minimumAttempts else { return nil }
            return (mode, attempts.filter(\.finished).count, attempts.count)
        }
        let best = results.max { a, b in
            let aRate = Double(a.finished) / Double(a.total)
            let bRate = Double(b.finished) / Double(b.total)
            return aRate == bRate ? a.finished < b.finished : aRate < bRate
        }
        guard let best, best.finished > 0 else { return nil }
        return Suggestion(
            mode: best.mode,
            reason: "You finished \(best.finished) of \(best.total) \(best.mode.rawValue) sessions in the \(part.rawValue)."
        )
    }
}

final class SuggestionsViewModel: ObservableObject {
    @Published private(set) var sessions: [SessionRecord] = []

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

    var general: Suggestion {
        StudySuggestions.general(sessions: sessions, now: now())
    }

    var personal: Suggestion? {
        StudySuggestions.personal(sessions: sessions, now: now())
    }

    /// Shown while history has no suggestion to make.
    var personalProgress: String {
        let part = PartOfDay(hour: Calendar.current.component(.hour, from: now()))
        let count = StudySuggestions.focusSessions(sessions, in: part).count
        if count >= StudySuggestions.sessionsNeeded {
            return "Not enough finished sessions in the \(part.rawValue) yet."
        }
        return "\(count) of \(StudySuggestions.sessionsNeeded) focus sessions in the \(part.rawValue) so far."
    }

    private func reload() {
        let request = NSFetchRequest<TimerSession>(entityName: "TimerSession")
        let stored = (try? context.fetch(request)) ?? []
        sessions = stored.compactMap { session in
            guard let mode = session.mode.flatMap(TimerMode.init(rawValue:)),
                  let startedAt = session.startedAt,
                  let endedAt = session.endedAt else { return nil }
            return SessionRecord(mode: mode, startedAt: startedAt, endedAt: endedAt, finished: session.finished)
        }
    }
}
