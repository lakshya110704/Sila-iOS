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

    var timerClock: TimerClock {
        TimerClock(now: { self.now }) { handler in
            self.handler = handler
            return { self.handler = nil }
        }
    }

    /// Time passes with the app in the foreground, so ticks fire.
    func advance(seconds: Int) {
        for _ in 0..<seconds {
            now += 1
            handler?()
        }
    }

    /// Time passes with the app suspended, so no ticks fire.
    func passWithoutTicks(seconds: TimeInterval) {
        now += seconds
    }
}

struct TimerViewModelTests {
    private let fake = FakeClock()

    private func makeTimer() -> TimerViewModel {
        TimerViewModel(clock: fake.timerClock)
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
    private func addTask(on date: Date?, minutes: Int64, completed: Bool = true) throws -> StudyTask {
        let task = NSEntityDescription.insertNewObject(forEntityName: "StudyTask", into: context) as! StudyTask
        task.title = "Task"
        task.date = date
        task.duration = minutes
        task.completed = completed
        try context.save()
        return task
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
