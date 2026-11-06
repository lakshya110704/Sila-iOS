//
//  TaskFlowUITests.swift
//  SilaUITests
//

import XCTest

final class TaskFlowUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        // The template launch tests can leave the simulator in landscape, which hides rows.
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["--in-memory-store"]
        app.launch()
    }

    /// Adds a task dated now and returns its title.
    private func addTask() -> String {
        let title = "Task \(UUID().uuidString.prefix(8))"
        let add = app.buttons["Add Task"]
        XCTAssertTrue(add.waitForExistence(timeout: 30))
        let save = app.buttons["Save"]
        add.tap(until: save)
        XCTAssertFalse(save.isEnabled)
        let titleField = app.textFields["Title"]
        // A tap during the sheet's animation doesn't give the field keyboard focus.
        for _ in 0..<10 where titleField.value(forKey: "hasKeyboardFocus") as? Bool != true {
            titleField.tap()
            sleep(1)
        }
        titleField.typeText(title)
        XCTAssertTrue(save.isEnabled)
        save.tap()
        return title
    }

    private func row(_ title: String) -> XCUIElement {
        app.cells.containing(.staticText, identifier: title).firstMatch
    }

    func testCompletedTaskAppearsInSummary() {
        let title = addTask()
        let row = row(title)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(row.buttons["Mark complete"].frame.height, 44)
        row.buttons["Mark complete"].tap(until: row.buttons["Mark incomplete"])

        app.tabBars.buttons["Summary"].tap(until: app.staticTexts[title])
    }

    func testWeekSwitcherShowsOnlyThatWeeksTasks() {
        let title = addTask()
        XCTAssertTrue(row(title).waitForExistence(timeout: 10))
        let thisWeek = app.staticTexts["weekLabel"].label

        app.buttons["Next week"].tap(until: app.buttons["This Week"])
        XCTAssertNotEqual(app.staticTexts["weekLabel"].label, thisWeek)
        XCTAssertFalse(row(title).exists)

        app.buttons["This Week"].tap(until: row(title))
        XCTAssertEqual(app.staticTexts["weekLabel"].label, thisWeek)

        app.buttons["Previous week"].tap(until: app.buttons["This Week"])
        XCTAssertFalse(row(title).exists)
    }

    func testDeletingATaskRemovesIt() {
        let keep = addTask()
        XCTAssertTrue(row(keep).waitForExistence(timeout: 10))
        let remove = addTask()
        XCTAssertTrue(row(remove).waitForExistence(timeout: 10))

        row(remove).swipeLeft()
        app.buttons["Delete"].tap()
        let gone = NSPredicate(format: "exists == false")
        wait(for: [expectation(for: gone, evaluatedWith: row(remove))], timeout: 10)
        XCTAssertTrue(row(keep).exists)
    }
}
