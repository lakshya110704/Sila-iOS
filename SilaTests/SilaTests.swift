//
//  SilaTests.swift
//  SilaTests
//
//  Created by Lakshya Mehta on 07/08/25.
//

import Testing
import CoreData
@testable import Sila

/// Stands in for the real clock so tests control when the timer ticks.
final class FakeClock {
    private var handler: (() -> Void)?
    private var now = Date(timeIntervalSinceReferenceDate: 0)
    private var uptime: TimeInterval = 1000
    private var bootID = "first boot"

    var timerClock: TimerClock {
        TimerClock(
            now: { self.now },
            uptime: { self.uptime },
            bootID: { self.bootID },
            scheduleTicks: { handler in
                self.handler = handler
                return { self.handler = nil }
            }
        )
    }

    /// Time passes with the app in the foreground, so ticks fire.
    func advance(seconds: Int) {
        for _ in 0..<seconds {
            now += 1
            uptime += 1
            handler?()
        }
    }

    /// Time passes with the app suspended, so no ticks fire.
    func passWithoutTicks(seconds: TimeInterval) {
        now += seconds
        uptime += seconds
    }

    /// The user changes the time in Settings. No time actually passes.
    func changeDeviceClock(by seconds: TimeInterval) {
        now += seconds
    }

    /// The device restarts after the given time. Uptime starts again.
    func reboot(after seconds: TimeInterval) {
        now += seconds
        uptime = 5
        bootID = "second boot"
    }
}

/// Records what the timer asks the notification center to do.
final class NotificationLog {
    var events: [String] = []

    var notifier: TimerNotifier {
        TimerNotifier(
            scheduleFinish: { mode, seconds in self.events.append("schedule \(mode.rawValue) \(seconds)") },
            cancelFinish: { self.events.append("cancel") }
        )
    }
}

/// Records the sessions the timer reports as ended.
final class EndedSessions {
    var items: [(mode: TimerMode, length: TimeInterval, finished: Bool)] = []
}

struct TimerViewModelTests {
    private let fake = FakeClock()
    private let defaults = UserDefaults(suiteName: UUID().uuidString)!

    private let notifications = NotificationLog()
    private let ended = EndedSessions()

    /// Calling this again acts like the app launching after being terminated.
    private func makeTimer() -> TimerViewModel {
        TimerViewModel(clock: fake.timerClock, defaults: defaults, notifier: notifications.notifier) { mode, start, end, finished in
            self.ended.items.append((mode, end.timeIntervalSince(start), finished))
        }
    }

    @Test func finishingRecordsAFinishedSession() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.advance(seconds: 5 * 60)

        #expect(ended.items.count == 1)
        #expect(ended.items[0].mode == .breakMode)
        #expect(ended.items[0].length == 300)
        #expect(ended.items[0].finished)
    }

    @Test func resettingAfterAMinuteRecordsAnUnfinishedSession() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 60)
        timer.reset()

        #expect(ended.items.count == 1)
        #expect(ended.items[0].mode == .pomodoro)
        #expect(!ended.items[0].finished)
    }

    @Test func resettingWithinAMinuteRecordsNothing() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 59)
        timer.reset()
        #expect(ended.items.isEmpty)
    }

    @Test func resettingAnIdleTimerRecordsNothing() {
        let timer = makeTimer()
        fake.advance(seconds: 100)
        timer.reset()
        #expect(ended.items.isEmpty)
    }

    @Test func changingModeRecordsTheSessionUnderItsOwnMode() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 120)
        timer.mode = .deepWork

        #expect(ended.items.count == 1)
        #expect(ended.items[0].mode == .pomodoro)
        #expect(!ended.items[0].finished)
    }

    @Test func pausingAndResumingIsOneSession() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.advance(seconds: 100)
        timer.pause()
        #expect(ended.items.isEmpty)
        fake.passWithoutTicks(seconds: 50)
        timer.start()
        fake.advance(seconds: 200)

        #expect(ended.items.count == 1)
        #expect(ended.items[0].finished)
        #expect(ended.items[0].length == 350)
    }

    @Test func aSessionThatFinishesWhileTerminatedIsRecordedOnLaunch() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.passWithoutTicks(seconds: 3600)

        _ = makeTimer()
        #expect(ended.items.count == 1)
        #expect(ended.items[0].mode == .breakMode)
        #expect(ended.items[0].finished)
        #expect(ended.items[0].length == 300)

        _ = makeTimer()
        #expect(ended.items.count == 1)
    }

    @Test func aFinishedTimerStartedAgainIsANewSession() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.advance(seconds: 300)
        timer.start()
        fake.advance(seconds: 300)
        #expect(ended.items.count == 2)
    }

    @Test func startSchedulesANotificationForTheTimeLeft() {
        let timer = makeTimer()
        timer.mode = .breakMode
        notifications.events.removeAll()

        timer.start()
        #expect(notifications.events == ["schedule Break 300"])
    }

    @Test func resumingSchedulesOnlyTheTimeLeft() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 100)
        timer.pause()
        notifications.events.removeAll()

        timer.start()
        #expect(notifications.events == ["schedule Pomodoro 1400"])
    }

    @Test func pauseResetAndChangingModeCancelTheNotification() {
        let timer = makeTimer()
        timer.start()
        notifications.events.removeAll()
        timer.pause()
        #expect(notifications.events == ["cancel"])

        timer.start()
        notifications.events.removeAll()
        timer.reset()
        #expect(notifications.events == ["cancel"])

        timer.start()
        notifications.events.removeAll()
        timer.mode = .deepWork
        #expect(notifications.events == ["cancel"])
    }

    @Test func restoringARunningTimerLeavesItsNotificationAlone() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        notifications.events.removeAll()

        _ = makeTimer()
        #expect(notifications.events.isEmpty)
    }

    @Test func modeDurations() {
        #expect(TimerMode.pomodoro.seconds == 25 * 60)
        #expect(TimerMode.deepWork.seconds == 90 * 60)
        #expect(TimerMode.breakMode.seconds == 5 * 60)
    }

    @Test func startsIdleOnPomodoro() {
        let timer = makeTimer()
        #expect(timer.mode == .pomodoro)
        #expect(timer.timeRemaining == 25 * 60)
        #expect(!timer.isRunning)
        #expect(timer.timeString == "25:00")
    }

    @Test func doesNotCountDownBeforeStart() {
        let timer = makeTimer()
        fake.advance(seconds: 10)
        #expect(timer.timeRemaining == 25 * 60)
    }

    @Test func countsDownOnceStarted() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 61)
        #expect(timer.isRunning)
        #expect(timer.timeRemaining == 25 * 60 - 61)
        #expect(timer.timeString == "23:59")
    }

    @Test func stopsAtZero() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.advance(seconds: 5 * 60)
        #expect(timer.timeRemaining == 0)
        #expect(!timer.isRunning)
    }

    @Test func startAfterFinishingRunsTheFullDurationAgain() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.advance(seconds: 5 * 60)
        timer.start()
        #expect(timer.timeRemaining == 5 * 60)
        #expect(timer.isRunning)
    }

    @Test func pauseFreezesAndStartResumes() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        timer.pause()
        fake.advance(seconds: 30)
        #expect(!timer.isRunning)
        #expect(timer.timeRemaining == 25 * 60 - 10)

        timer.start()
        fake.advance(seconds: 5)
        #expect(timer.timeRemaining == 25 * 60 - 15)
    }

    @Test func resetRestoresDurationAndStops() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        timer.reset()
        fake.advance(seconds: 10)
        #expect(!timer.isRunning)
        #expect(timer.timeRemaining == 25 * 60)
    }

    @Test func changingModeStopsAndLoadsItsDuration() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        timer.mode = .deepWork
        fake.advance(seconds: 10)
        #expect(!timer.isRunning)
        #expect(timer.timeRemaining == 90 * 60)
    }

    @Test func timeInTheBackgroundCountsOnReturn() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        fake.passWithoutTicks(seconds: 600)
        #expect(timer.timeRemaining == 25 * 60 - 10)

        timer.refresh()
        #expect(timer.isRunning)
        #expect(timer.timeRemaining == 25 * 60 - 610)
    }

    @Test func firstTickAfterBackgroundCatchesUp() {
        let timer = makeTimer()
        timer.start()
        fake.passWithoutTicks(seconds: 600)
        fake.advance(seconds: 1)
        #expect(timer.timeRemaining == 25 * 60 - 601)
    }

    @Test func finishingInTheBackgroundStopsAtZero() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.passWithoutTicks(seconds: 3600)
        timer.refresh()
        #expect(timer.timeRemaining == 0)
        #expect(!timer.isRunning)
    }

    @Test func pausedTimerIgnoresTimeInTheBackground() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        timer.pause()
        fake.passWithoutTicks(seconds: 600)
        timer.refresh()
        #expect(!timer.isRunning)
        #expect(timer.timeRemaining == 25 * 60 - 10)

        timer.start()
        fake.advance(seconds: 5)
        #expect(timer.timeRemaining == 25 * 60 - 15)
    }

    @Test func pauseCountsTimeSinceTheLastTick() {
        let timer = makeTimer()
        timer.start()
        fake.passWithoutTicks(seconds: 600)
        timer.pause()
        #expect(timer.timeRemaining == 25 * 60 - 600)
    }

    @Test func partOfASecondRoundsUp() {
        let timer = makeTimer()
        timer.start()
        fake.passWithoutTicks(seconds: 0.5)
        timer.refresh()
        #expect(timer.timeRemaining == 25 * 60)
    }

    @Test func changingTheDeviceClockDoesNotShiftARunningTimer() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)

        fake.changeDeviceClock(by: 3600)
        timer.refresh()
        #expect(timer.isRunning)
        #expect(timer.timeRemaining == 25 * 60 - 10)

        fake.changeDeviceClock(by: -7200)
        fake.advance(seconds: 5)
        #expect(timer.timeRemaining == 25 * 60 - 15)
    }

    @Test func changingTheDeviceClockDoesNotShiftATimerAfterTermination() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        fake.changeDeviceClock(by: 3600)

        let restored = makeTimer()
        #expect(restored.isRunning)
        #expect(restored.timeRemaining == 25 * 60 - 10)
    }

    @Test func aRebootFallsBackToTheDeviceClock() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        fake.reboot(after: 100)

        let restored = makeTimer()
        #expect(restored.isRunning)
        #expect(restored.timeRemaining == 25 * 60 - 110)

        fake.advance(seconds: 5)
        #expect(restored.timeRemaining == 25 * 60 - 115)
    }

    @Test func aTimerThatEndsDuringARebootIsFinished() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.reboot(after: 3600)

        let restored = makeTimer()
        #expect(!restored.isRunning)
        #expect(restored.timeRemaining == 0)
    }

    @Test func aSavedTimerFromBeforeUptimeWasStoredStillRestores() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        defaults.removeObject(forKey: "timer.endUptime")
        defaults.removeObject(forKey: "timer.bootID")

        let restored = makeTimer()
        #expect(restored.isRunning)
        #expect(restored.timeRemaining == 25 * 60 - 10)
    }

    @Test func runningTimerSurvivesTermination() {
        let timer = makeTimer()
        timer.mode = .deepWork
        timer.start()
        fake.advance(seconds: 10)
        fake.passWithoutTicks(seconds: 600)

        let restored = makeTimer()
        #expect(restored.mode == .deepWork)
        #expect(restored.isRunning)
        #expect(restored.timeRemaining == 90 * 60 - 610)

        fake.advance(seconds: 5)
        #expect(restored.timeRemaining == 90 * 60 - 615)
    }

    @Test func pausedTimerSurvivesTermination() {
        let timer = makeTimer()
        timer.mode = .deepWork
        timer.start()
        fake.advance(seconds: 10)
        timer.pause()
        fake.passWithoutTicks(seconds: 600)

        let restored = makeTimer()
        #expect(restored.mode == .deepWork)
        #expect(!restored.isRunning)
        #expect(restored.timeRemaining == 90 * 60 - 10)
    }

    @Test func timerFinishingWhileTerminatedStaysFinished() {
        let timer = makeTimer()
        timer.mode = .breakMode
        timer.start()
        fake.passWithoutTicks(seconds: 3600)

        let restored = makeTimer()
        #expect(restored.timeRemaining == 0)
        #expect(!restored.isRunning)

        let restoredAgain = makeTimer()
        #expect(restoredAgain.timeRemaining == 0)
        #expect(!restoredAgain.isRunning)
    }

    @Test func resetTimerStaysResetAfterTermination() {
        let timer = makeTimer()
        timer.start()
        fake.advance(seconds: 10)
        timer.reset()
        fake.passWithoutTicks(seconds: 600)

        let restored = makeTimer()
        #expect(!restored.isRunning)
        #expect(restored.timeRemaining == 25 * 60)
    }
}

struct AddTaskValidationTests {
    @Test func acceptsATitleAndPositiveDuration() {
        #expect(AddTaskView.isValid(title: "Read chapter 3", duration: 30))
    }

    @Test func rejectsAnEmptyTitle() {
        #expect(!AddTaskView.isValid(title: "", duration: 30))
    }

    @Test func rejectsAWhitespaceTitle() {
        #expect(!AddTaskView.isValid(title: "  \n ", duration: 30))
    }

    @Test func rejectsAZeroDuration() {
        #expect(!AddTaskView.isValid(title: "Read chapter 3", duration: 0))
    }
}

// The view context belongs to the main queue, so these stay on the main actor.
@MainActor
struct ProductivitySummaryViewModelTests {
    private let context = PersistenceController(inMemory: true).container.viewContext
    private let today = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 12))!

    private func makeSummary() -> ProductivitySummaryViewModel {
        let today = today
        return ProductivitySummaryViewModel(context: context, now: { today })
    }

    private func date(daysAgo: Int, hour: Int = 12) -> Date {
        let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
    }

    // Looks the entity up by name because +[StudyTask entity] is ambiguous when
    // several containers have loaded the model, as they do across these tests.
    @discardableResult
    private func addTask(on date: Date?, minutes: Int64, completed: Bool = true, completedAt: Date? = nil) throws -> StudyTask {
        let task = NSEntityDescription.insertNewObject(forEntityName: "StudyTask", into: context) as! StudyTask
        task.title = "Task"
        task.date = date
        task.duration = minutes
        task.completed = completed
        task.completedAt = completedAt
        try context.save()
        return task
    }

    @Test func minutesCountOnTheDayCompletedNotTheDayScheduled() throws {
        try addTask(on: date(daysAgo: 5), minutes: 30, completedAt: date(daysAgo: 0))
        try addTask(on: date(daysAgo: 0), minutes: 60, completedAt: date(daysAgo: 1))

        let summary = makeSummary()
        #expect(summary.todayTotalMinutes == 30)
        #expect(summary.past7DaysData.map(\.totalMinutes) == [0, 0, 0, 0, 0, 60, 30])
    }

    @Test func taskWithoutACompletionDateCountsOnItsScheduledDate() throws {
        try addTask(on: date(daysAgo: 2), minutes: 30, completedAt: nil)
        #expect(makeSummary().past7DaysData.map(\.totalMinutes) == [0, 0, 0, 0, 30, 0, 0])
    }

    @Test func togglingSetsAndClearsTheCompletionDate() throws {
        let task = try addTask(on: date(daysAgo: 5), minutes: 30, completed: false)

        task.toggleCompleted(now: today)
        #expect(task.completed)
        #expect(task.completedAt == today)

        task.toggleCompleted(now: today)
        #expect(!task.completed)
        #expect(task.completedAt == nil)
    }

    @Test func storeStartsEmptyAndPersistsTasks() throws {
        #expect(try context.fetch(StudyTask.fetchRequest()).isEmpty)
        try addTask(on: today, minutes: 45, completed: false)

        let fetched = try context.fetch(StudyTask.fetchRequest())
        #expect(fetched.count == 1)
        #expect(fetched.first?.duration == 45)
        #expect(fetched.first?.completed == false)
    }

    @Test func todayTotalAddsCompletedTasksFromToday() throws {
        try addTask(on: date(daysAgo: 0, hour: 0), minutes: 30)
        try addTask(on: date(daysAgo: 0, hour: 23), minutes: 45)
        #expect(makeSummary().todayTotalMinutes == 75)
    }

    @Test func todayTotalIgnoresOtherDays() throws {
        try addTask(on: date(daysAgo: 0), minutes: 30)
        try addTask(on: date(daysAgo: 1, hour: 23), minutes: 60)
        try addTask(on: date(daysAgo: -1, hour: 0), minutes: 90)
        #expect(makeSummary().todayTotalMinutes == 30)
    }

    @Test func todayTotalIgnoresIncompleteTasks() throws {
        try addTask(on: date(daysAgo: 0), minutes: 30)
        try addTask(on: date(daysAgo: 0), minutes: 60, completed: false)
        #expect(makeSummary().todayTotalMinutes == 30)
    }

    @Test func todayTotalIgnoresTasksWithoutADate() throws {
        try addTask(on: nil, minutes: 60)
        #expect(makeSummary().todayTotalMinutes == 0)
    }

    @Test func weekHasSevenDaysOldestFirstEndingToday() {
        let days = makeSummary().past7DaysData.map(\.date)
        let expected = (0..<7).reversed().map { Calendar.current.startOfDay(for: date(daysAgo: $0)) }
        #expect(days == expected)
    }

    @Test func weekIsAllZerosWithNoTasks() {
        #expect(makeSummary().past7DaysData.map(\.totalMinutes) == [0, 0, 0, 0, 0, 0, 0])
    }

    @Test func weekPutsMinutesOnTheirDaysAndZerosOnEmptyDays() throws {
        try addTask(on: date(daysAgo: 6), minutes: 10)
        try addTask(on: date(daysAgo: 2), minutes: 20)
        try addTask(on: date(daysAgo: 2), minutes: 5)
        try addTask(on: date(daysAgo: 0), minutes: 30)
        try addTask(on: date(daysAgo: 1), minutes: 99, completed: false)
        try addTask(on: date(daysAgo: 7), minutes: 99)
        #expect(makeSummary().past7DaysData.map(\.totalMinutes) == [10, 0, 0, 0, 25, 0, 30])
    }

    @Test func updatesWhenTheContextSaves() throws {
        let summary = makeSummary()
        let task = try addTask(on: date(daysAgo: 0), minutes: 30, completed: false)
        #expect(summary.todayTotalMinutes == 0)

        task.completed = true
        try context.save()
        #expect(summary.todayTotalMinutes == 30)
        #expect(summary.completedTasks.count == 1)
    }
}

@MainActor
struct StoreMigrationTests {
    @Test func storeFromTheSecondModelKeepsCompletionDatesAndGainsSessions() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).sqlite")
        let completedAt = Date(timeIntervalSinceReferenceDate: 800_000_000)

        let momd = try #require(Bundle.main.url(forResource: "Sila", withExtension: "momd"))
        let oldModel = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("Sila 2.mom")))
        #expect(oldModel.entitiesByName["TimerSession"] == nil)
        let entity = try #require(oldModel.entitiesByName["StudyTask"])

        let oldContainer = NSPersistentContainer(name: "Sila", managedObjectModel: oldModel)
        oldContainer.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url)]
        oldContainer.loadPersistentStores { _, error in #expect(error == nil) }
        let oldTask = NSManagedObject(entity: entity, insertInto: oldContainer.viewContext)
        oldTask.setValue("Second model task", forKey: "title")
        oldTask.setValue(true, forKey: "completed")
        oldTask.setValue(completedAt, forKey: "completedAt")
        try oldContainer.viewContext.save()
        for store in oldContainer.persistentStoreCoordinator.persistentStores {
            try oldContainer.persistentStoreCoordinator.remove(store)
        }

        let context = PersistenceController(storeURL: url).container.viewContext
        let task = try #require(try context.fetch(StudyTask.fetchRequest()).first)
        #expect(task.title == "Second model task")
        #expect(task.completedAt == completedAt)

        TimerSession.record(mode: .pomodoro, startedAt: completedAt, endedAt: completedAt, finished: true, in: context)
        let sessions = try context.fetch(NSFetchRequest<TimerSession>(entityName: "TimerSession"))
        #expect(sessions.count == 1)
    }

    @Test func storeFromTheOldModelMigratesAndKeepsItsTasks() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).sqlite")
        let scheduled = Date(timeIntervalSinceReferenceDate: 800_000_000)

        // Write a real store with the first model version, as an older build of the app would have.
        let momd = try #require(Bundle.main.url(forResource: "Sila", withExtension: "momd"))
        let oldModel = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("Sila.mom")))
        let entity = try #require(oldModel.entitiesByName["StudyTask"])
        #expect(entity.attributesByName["completedAt"] == nil)

        let oldContainer = NSPersistentContainer(name: "Sila", managedObjectModel: oldModel)
        oldContainer.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url)]
        oldContainer.loadPersistentStores { _, error in #expect(error == nil) }
        let oldTask = NSManagedObject(entity: entity, insertInto: oldContainer.viewContext)
        oldTask.setValue("Old task", forKey: "title")
        oldTask.setValue(scheduled, forKey: "date")
        oldTask.setValue(Int64(45), forKey: "duration")
        oldTask.setValue(true, forKey: "completed")
        try oldContainer.viewContext.save()
        for store in oldContainer.persistentStoreCoordinator.persistentStores {
            try oldContainer.persistentStoreCoordinator.remove(store)
        }

        // Open it the way the app does.
        let context = PersistenceController(storeURL: url).container.viewContext
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url)
        #expect(!oldModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata))

        let tasks = try context.fetch(StudyTask.fetchRequest())
        let task = try #require(tasks.first)
        #expect(tasks.count == 1)
        #expect(task.title == "Old task")
        #expect(task.date == scheduled)
        #expect(task.duration == 45)
        #expect(task.completed)
        #expect(task.completedAt == nil)

        let summary = ProductivitySummaryViewModel(context: context, now: { scheduled })
        #expect(summary.todayTotalMinutes == 45)

        // A migrated task can store a completion date like any other.
        task.toggleCompleted(now: scheduled)
        task.toggleCompleted(now: scheduled)
        try context.save()
        #expect(task.completedAt == scheduled)
    }
}

@MainActor
struct StudySuggestionsTests {
    private func date(hour: Int, day: Int = 15) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour))!
    }

    private func sessions(_ mode: TimerMode, finished: Int, unfinished: Int = 0, hour: Int = 9, day: Int = 10) -> [SessionRecord] {
        let start = date(hour: hour, day: day)
        let end = start.addingTimeInterval(TimeInterval(mode.seconds))
        return (0..<finished).map { _ in SessionRecord(mode: mode, startedAt: start, endedAt: end, finished: true) }
            + (0..<unfinished).map { _ in SessionRecord(mode: mode, startedAt: start, endedAt: end, finished: false) }
    }

    @Test func partsOfTheDayCoverEveryHour() {
        #expect(PartOfDay(hour: 4) == .night)
        #expect(PartOfDay(hour: 5) == .morning)
        #expect(PartOfDay(hour: 11) == .morning)
        #expect(PartOfDay(hour: 12) == .afternoon)
        #expect(PartOfDay(hour: 17) == .afternoon)
        #expect(PartOfDay(hour: 18) == .evening)
        #expect(PartOfDay(hour: 21) == .evening)
        #expect(PartOfDay(hour: 22) == .night)
    }

    @Test func generalSuggestionFollowsTheTimeOfDay() {
        #expect(StudySuggestions.general(sessions: [], now: date(hour: 9)).mode == .deepWork)
        #expect(StudySuggestions.general(sessions: [], now: date(hour: 14)).mode == .pomodoro)
        #expect(StudySuggestions.general(sessions: [], now: date(hour: 20)).mode == .pomodoro)
        #expect(StudySuggestions.general(sessions: [], now: date(hour: 23)).mode == .breakMode)
    }

    @Test func generalSuggestsABreakRightAfterFinishingFocus() {
        let now = date(hour: 9)
        let justDone = SessionRecord(mode: .pomodoro, startedAt: now.addingTimeInterval(-1600), endedAt: now.addingTimeInterval(-100), finished: true)
        #expect(StudySuggestions.general(sessions: [justDone], now: now).mode == .breakMode)
    }

    @Test func generalIgnoresOldUnfinishedAndBreakSessions() {
        let now = date(hour: 9)
        let old = SessionRecord(mode: .pomodoro, startedAt: now.addingTimeInterval(-9000), endedAt: now.addingTimeInterval(-1800), finished: true)
        let unfinished = SessionRecord(mode: .pomodoro, startedAt: now.addingTimeInterval(-600), endedAt: now.addingTimeInterval(-100), finished: false)
        let aBreak = SessionRecord(mode: .breakMode, startedAt: now.addingTimeInterval(-400), endedAt: now.addingTimeInterval(-100), finished: true)
        #expect(StudySuggestions.general(sessions: [old, unfinished, aBreak], now: now).mode == .deepWork)
    }

    @Test func historySaysNothingBelowFiveSessions() {
        let few = sessions(.pomodoro, finished: 4)
        #expect(StudySuggestions.personal(sessions: few, now: date(hour: 9)) == nil)
    }

    @Test func historyPicksTheModeFinishedMostReliably() {
        let history = sessions(.pomodoro, finished: 1, unfinished: 3) + sessions(.deepWork, finished: 3)
        let suggestion = StudySuggestions.personal(sessions: history, now: date(hour: 9))
        #expect(suggestion?.mode == .deepWork)
        #expect(suggestion?.reason == "You finished 3 of 3 Deep Work sessions in the morning.")
    }

    @Test func historyBreaksATieByFinishedCount() {
        let history = sessions(.pomodoro, finished: 2) + sessions(.deepWork, finished: 4)
        #expect(StudySuggestions.personal(sessions: history, now: date(hour: 9))?.mode == .deepWork)
    }

    @Test func historyIgnoresAModeTriedOnlyOnce() {
        let history = sessions(.pomodoro, finished: 3, unfinished: 2) + sessions(.deepWork, finished: 1)
        #expect(StudySuggestions.personal(sessions: history, now: date(hour: 9))?.mode == .pomodoro)
    }

    @Test func historyOnlyCountsThisPartOfTheDay() {
        let evening = sessions(.deepWork, finished: 6, hour: 20)
        #expect(StudySuggestions.personal(sessions: evening, now: date(hour: 9)) == nil)
        #expect(StudySuggestions.personal(sessions: evening, now: date(hour: 20))?.mode == .deepWork)
    }

    @Test func historyDoesNotCountBreaks() {
        let breaks = sessions(.breakMode, finished: 10)
        #expect(StudySuggestions.personal(sessions: breaks, now: date(hour: 9)) == nil)
    }

    @Test func historySaysNothingIfNothingWasFinished() {
        let history = sessions(.pomodoro, finished: 0, unfinished: 6)
        #expect(StudySuggestions.personal(sessions: history, now: date(hour: 9)) == nil)
    }

    @Test func viewModelStoresSessionsAndLearnsFromThem() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let now = date(hour: 9)
        let model = SuggestionsViewModel(context: context, now: { now })
        #expect(model.personal == nil)
        #expect(model.personalProgress == "0 of 5 focus sessions in the morning so far.")

        let start = date(hour: 9, day: 10)
        for _ in 0..<5 {
            TimerSession.record(mode: .deepWork, startedAt: start, endedAt: start.addingTimeInterval(5400), finished: true, in: context)
        }
        #expect(model.sessions.count == 5)
        #expect(model.personal?.mode == .deepWork)
    }

    @Test func viewModelExplainsHistoryWithNoFinishedSessions() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let now = date(hour: 9)
        let model = SuggestionsViewModel(context: context, now: { now })
        let start = date(hour: 9, day: 10)
        for _ in 0..<5 {
            TimerSession.record(mode: .pomodoro, startedAt: start, endedAt: start.addingTimeInterval(300), finished: false, in: context)
        }
        #expect(model.personal == nil)
        #expect(model.personalProgress == "Not enough finished sessions in the morning yet.")
    }
}

@MainActor
struct PlannerWeekTests {
    private let context = PersistenceController(inMemory: true).container.viewContext
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()

    private func date(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour))!
    }

    private func task(on date: Date?) -> StudyTask {
        let task = NSEntityDescription.insertNewObject(forEntityName: "StudyTask", into: context) as! StudyTask
        task.date = date
        return task
    }

    // 16 March 2026 is a Monday.
    @Test func weekStartsOnTheCalendarsFirstDay() {
        let monday = calendar.startOfDay(for: date(16))
        #expect(PlannerWeek.start(of: date(16), calendar: calendar) == monday)
        #expect(PlannerWeek.start(of: date(18), calendar: calendar) == monday)
        #expect(PlannerWeek.start(of: date(22, hour: 23), calendar: calendar) == monday)
        #expect(PlannerWeek.start(of: date(23), calendar: calendar) != monday)
    }

    @Test func aWeekHasSevenDaysInOrder() {
        let days = PlannerWeek.days(from: calendar.startOfDay(for: date(16)), tasks: [], calendar: calendar)
        #expect(days.map(\.date) == (16...22).map { calendar.startOfDay(for: date($0)) })
    }

    @Test func tasksLandOnTheirOwnDayInTheOrderGiven() {
        let early = task(on: date(18, hour: 8))
        let late = task(on: date(18, hour: 20))
        let sunday = task(on: date(22, hour: 23))
        let days = PlannerWeek.days(from: calendar.startOfDay(for: date(16)), tasks: [early, late, sunday], calendar: calendar)

        #expect(days[2].tasks == [early, late])
        #expect(days[6].tasks == [sunday])
        #expect(days.map(\.tasks.count) == [0, 0, 2, 0, 0, 0, 1])
    }

    @Test func tasksFromOtherWeeksAndWithoutADateAreLeftOut() {
        let lastSunday = task(on: date(15, hour: 23))
        let nextMonday = task(on: date(23, hour: 0))
        let undated = task(on: nil)
        let days = PlannerWeek.days(from: calendar.startOfDay(for: date(16)), tasks: [lastSunday, nextMonday, undated], calendar: calendar)

        #expect(days.allSatisfy { $0.tasks.isEmpty })
    }
}
