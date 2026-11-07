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
        let titleField = focusedTitleField()
        titleField.typeText(title)
        XCTAssertTrue(save.isEnabled)
        save.tap()
        return title
    }

    private func focusedTitleField() -> XCUIElement {
        let titleField = app.textFields["Title"]
        // A tap during the sheet's animation doesn't give the field keyboard focus.
        for _ in 0..<10 where titleField.value(forKey: "hasKeyboardFocus") as? Bool != true {
            titleField.tap()
            sleep(1)
        }
        return titleField
    }

    private func openEditor(for title: String) {
        let row = row(title)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.staticTexts[title].tap(until: app.navigationBars["Edit Study Task"])
    }

    private func waitUntilGone(_ element: XCUIElement) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter.wait(for: [gone], timeout: 10) == .completed
    }

    private func clearText(of field: XCUIElement) {
        let length = (field.value as? String)?.count ?? 0
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length))
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

    func testEditingATaskChangesIt() {
        let title = addTask()
        openEditor(for: title)
        let field = focusedTitleField()
        XCTAssertEqual(field.value as? String, title)

        clearText(of: field)
        field.typeText("Renamed task")
        app.buttons["Save"].tap()

        XCTAssertTrue(row("Renamed task").waitForExistence(timeout: 10))
        XCTAssertFalse(row(title).exists)
    }

    func testCancellingAnEditLeavesTheTaskAlone() {
        let title = addTask()
        openEditor(for: title)
        let field = focusedTitleField()
        clearText(of: field)
        field.typeText("Should not save")
        app.buttons["Cancel"].tap()

        XCTAssertTrue(row(title).waitForExistence(timeout: 10))
        XCTAssertFalse(row("Should not save").exists)
    }

    func testAnEditCannotBlankTheTitle() {
        let title = addTask()
        openEditor(for: title)
        let field = focusedTitleField()
        clearText(of: field)
        let disabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == false"), object: app.buttons["Save"])
        let result = XCTWaiter.wait(for: [disabled], timeout: 5)
        XCTAssertEqual(result, .completed)
    }

    func testEditingKeepsATaskCompleted() {
        let title = addTask()
        let row = row(title)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.buttons["Mark complete"].tap(until: row.buttons["Mark incomplete"])

        openEditor(for: title)
        app.buttons["Save"].tap()
        XCTAssertTrue(row.buttons["Mark incomplete"].waitForExistence(timeout: 10))
    }

    func testDeletingATaskRemovesIt() {
        let keep = addTask()
        XCTAssertTrue(row(keep).waitForExistence(timeout: 10))
        let remove = addTask()
        XCTAssertTrue(row(remove).waitForExistence(timeout: 10))

        // A swipe while the Add sheet is still closing doesn't reveal the button.
        let delete = app.buttons["Delete"]
        XCTAssertTrue(waitUntilGone(app.buttons["Save"]))
        row(remove).swipeLeft()
        if !delete.waitForExistence(timeout: 5) {
            row(remove).swipeLeft()
        }
        delete.tap()
        XCTAssertTrue(waitUntilGone(row(remove)))
        XCTAssertTrue(row(keep).exists)
    }
}
