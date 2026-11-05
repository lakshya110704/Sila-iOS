//
//  TaskFlowUITests.swift
//  SilaUITests
//

import XCTest

final class TaskFlowUITests: XCTestCase {
    func testCompletedTaskAppearsInSummary() {
        continueAfterFailure = false
        // The template launch tests can leave the simulator in landscape, which hides this row.
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--in-memory-store"]
        app.launch()

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

        let row = app.cells.containing(.staticText, identifier: title).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.buttons["Mark complete"].tap(until: row.buttons["Mark incomplete"])

        app.tabBars.buttons["Summary"].tap(until: app.staticTexts[title])
    }
}
