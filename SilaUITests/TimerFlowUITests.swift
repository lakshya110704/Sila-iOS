//
//  TimerFlowUITests.swift
//  SilaUITests
//

import XCTest

final class TimerFlowUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        openTimer()
        app.buttons["Reset"].tap()
    }

    private func openTimer() {
        let tab = app.tabBars.buttons["Timer"]
        XCTAssertTrue(tab.waitForExistence(timeout: 30))
        tab.tap()
    }

    /// The seconds left, read from the "mm:ss" label on screen.
    private var secondsOnScreen: Int {
        let parts = app.staticTexts["timeRemaining"].label.split(separator: ":").compactMap { Int($0) }
        XCTAssertEqual(parts.count, 2)
        return parts[0] * 60 + parts[1]
    }

    private func startTimer() -> Int {
        let start = secondsOnScreen
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        return start
    }

    private func assertStillRunning(start: Int, afterAtLeast seconds: Int) {
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(secondsOnScreen, start - seconds)
    }

    func testTimerKeepsRunningAcrossTabs() {
        let start = startTimer()
        app.tabBars.buttons["Planner"].tap()
        sleep(5)
        openTimer()
        assertStillRunning(start: start, afterAtLeast: 5)
    }

    func testTimerCountsTimeInTheBackground() {
        let start = startTimer()
        XCUIDevice.shared.press(.home)
        sleep(15)
        app.activate()
        assertStillRunning(start: start, afterAtLeast: 15)
    }
}
