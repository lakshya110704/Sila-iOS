//
//  TimerFlowUITests.swift
//  SilaUITests
//

import XCTest

final class TimerFlowUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        openTimer()
        app.buttons["Reset"].tap(until: app.buttons["Start"])
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
        app.buttons["Start"].tap(until: app.buttons["Pause"])
        // Pressing Start asks for notification permission on a fresh install.
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.buttons["Allow"]
        if allow.waitForExistence(timeout: 2) {
            allow.tap()
        }
        return start
    }

    private func assertStillRunning(start: Int, afterAtLeast seconds: Int) {
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(secondsOnScreen, start - seconds)
    }

    func testTimerButtonsMeetTheMinimumTapSize() {
        XCTAssertGreaterThanOrEqual(app.buttons["Start"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["Reset"].frame.height, 44)
    }

    func testBothSuggestionsShowAndGeneralCanBeUsed() {
        XCTAssertTrue(app.staticTexts["General"].exists)
        XCTAssertTrue(app.staticTexts["Your History"].exists)

        let mode = app.staticTexts["generalSuggestionMode"].label
        let use = app.buttons["generalSuggestionUse"]
        XCTAssertTrue(use.exists)
        // Choose a different mode first, so using the suggestion has something to change.
        let other = mode == "Pomodoro" ? "Break" : "Pomodoro"
        app.buttons[other].tap()
        XCTAssertTrue(use.isEnabled)
        use.tap()
        XCTAssertTrue(app.buttons[mode].isSelected)
        XCTAssertFalse(use.isEnabled)

        // A running timer can't be replaced by tapping a suggestion.
        app.buttons[other].tap()
        _ = startTimer()
        XCTAssertFalse(use.isEnabled)
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

    func testRunningTimerSurvivesTermination() {
        let start = startTimer()
        app.terminate()
        sleep(15)
        app.launch()
        openTimer()
        assertStillRunning(start: start, afterAtLeast: 15)
    }

    func testResetStopsARestoredTimer() {
        let start = startTimer()
        app.terminate()
        app.launch()
        openTimer()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))

        app.buttons["Reset"].tap(until: app.buttons["Start"])
        XCTAssertEqual(secondsOnScreen, start)
    }
}

extension XCUIElement {
    /// Retries once because a tap occasionally had no visible effect in earlier runs, cause unknown.
    /// A tap that never works still fails the test.
    func tap(until expected: XCUIElement) {
        tap()
        if !expected.waitForExistence(timeout: 10) {
            tap()
        }
        XCTAssertTrue(expected.waitForExistence(timeout: 10))
    }
}
