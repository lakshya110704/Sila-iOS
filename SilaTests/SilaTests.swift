//
//  SilaTests.swift
//  SilaTests
//
//  Created by Lakshya Mehta on 07/08/25.
//

import Testing
import CoreData
@testable import Sila

struct SilaTests {

    @Test func timerModeDurations() {
        #expect(TimerMode.pomodoro.seconds == 25 * 60)
        #expect(TimerMode.deepWork.seconds == 90 * 60)
        #expect(TimerMode.breakMode.seconds == 5 * 60)
    }

    @Test func studyTaskPersists() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let task = StudyTask(context: context)
        task.title = "Read ch. 3"
        task.duration = 45
        try context.save()

        let fetched = try context.fetch(StudyTask.fetchRequest())
        #expect(fetched.count == 1)
        #expect(fetched.first?.completed == false)
    }

}
