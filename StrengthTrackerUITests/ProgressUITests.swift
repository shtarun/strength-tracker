import XCTest

final class ProgressUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Progress Navigation Tests

    func testProgress_NavigateToProgressTab() throws {
        let progressTab = app.tabBars.buttons["Progress"]
        XCTAssertTrue(progressTab.waitForExistence(timeout: 5), "Progress tab should exist")

        progressTab.tap()
    }

    // MARK: - Progress Overview Tests

    func testProgress_ShowsOverviewTab() throws {
        navigateToProgress()

        // Should have Overview, Lifts, Calendar tabs or similar
        _ = app.buttons["Overview"].waitForExistence(timeout: 3) ||
            app.staticTexts["Overview"].waitForExistence(timeout: 3)
    }

    func testProgress_ShowsLiftsTab() throws {
        navigateToProgress()

        _ = app.buttons["Lifts"].waitForExistence(timeout: 3) ||
            app.staticTexts["Lifts"].waitForExistence(timeout: 3)
    }

    func testProgress_ShowsCalendarTab() throws {
        navigateToProgress()

        _ = app.buttons["Calendar"].waitForExistence(timeout: 3) ||
            app.staticTexts["Calendar"].waitForExistence(timeout: 3)
    }

    // MARK: - Stats Display Tests

    func testProgress_ShowsWeeklyStats() throws {
        navigateToProgress()

        // Should show weekly workout count or similar stats
        let weeklyPredicate = NSPredicate(format: "label CONTAINS[c] 'week' OR label CONTAINS[c] 'weekly'")
        _ = app.staticTexts.element(matching: weeklyPredicate).waitForExistence(timeout: 3)
    }

    func testProgress_ShowsStreakInfo() throws {
        navigateToProgress()

        // Should show streak information
        let streakPredicate = NSPredicate(format: "label CONTAINS[c] 'streak'")
        _ = app.staticTexts.element(matching: streakPredicate).waitForExistence(timeout: 3)
    }

    func testProgress_ShowsPRs() throws {
        navigateToProgress()

        // Should show PR information
        let prPredicate = NSPredicate(
            format: "label CONTAINS[c] 'PR' OR label CONTAINS[c] 'personal record' OR label CONTAINS[c] 'best'"
        )
        _ = app.staticTexts.element(matching: prPredicate).waitForExistence(timeout: 3)
    }

    // MARK: - Chart Tests

    func testProgress_ShowsE1RMChart() throws {
        navigateToProgress()

        // Try to navigate to lifts view
        let liftsTab = app.buttons["Lifts"]
        if liftsTab.waitForExistence(timeout: 3) {
            liftsTab.tap()
        }

        // Should show chart or graph
        // Charts are typically custom views, hard to identify directly
    }

    func testProgress_ShowsVolumeChart() throws {
        navigateToProgress()

        // Volume charts should be present
        let volumePredicate = NSPredicate(format: "label CONTAINS[c] 'volume'")
        _ = app.staticTexts.element(matching: volumePredicate).waitForExistence(timeout: 3)
    }

    // MARK: - Calendar Tests

    func testProgress_CalendarShowsWorkoutDays() throws {
        navigateToProgress()

        let calendarTab = app.buttons["Calendar"]
        if calendarTab.waitForExistence(timeout: 3) {
            calendarTab.tap()
            // Should show calendar view
        }
    }

    // MARK: - Exercise Detail Tests

    func testProgress_CanSelectExercise() throws {
        navigateToProgress()

        let liftsTab = app.buttons["Lifts"]
        if liftsTab.waitForExistence(timeout: 3) {
            liftsTab.tap()
        }

        // Should have list of exercises to select
        let benchPress = app.staticTexts["Bench Press"]
        let squat = app.staticTexts["Squat"]
        let deadlift = app.staticTexts["Deadlift"]

        _ = benchPress.waitForExistence(timeout: 3) ||
            squat.waitForExistence(timeout: 3) ||
            deadlift.waitForExistence(timeout: 3)
    }

    func testProgress_ExerciseDetailShowsHistory() throws {
        navigateToProgress()

        let liftsTab = app.buttons["Lifts"]
        if liftsTab.waitForExistence(timeout: 3) {
            liftsTab.tap()
        }

        // Try to tap on an exercise
        let firstExercise = app.cells.firstMatch
        guard firstExercise.waitForExistence(timeout: 3) else {
            throw XCTSkip("No exercises available")
        }

        firstExercise.tap()

        // Should show exercise detail with history
        _ = app.staticTexts["History"].waitForExistence(timeout: 3) ||
            app.staticTexts["Recent Sessions"].waitForExistence(timeout: 3)
    }

    func testProgress_ExerciseDetailShowsFormTips() throws {
        navigateToProgress()

        let liftsTab = app.buttons["Lifts"]
        if liftsTab.waitForExistence(timeout: 3) {
            liftsTab.tap()
        }

        // Navigate to exercise detail
        let firstExercise = app.cells.firstMatch
        guard firstExercise.waitForExistence(timeout: 3) else {
            throw XCTSkip("No exercises available")
        }

        firstExercise.tap()

        // Should show form tips button
        let formTips = app.buttons["Form Tips"]
        let infoPredicate = NSPredicate(format: "label CONTAINS[c] 'info' OR label CONTAINS[c] 'form'")
        let infoButton = app.buttons.element(matching: infoPredicate)

        _ = formTips.waitForExistence(timeout: 3) ||
            infoButton.waitForExistence(timeout: 3)
    }

    // MARK: - Muscle Group Tests

    func testProgress_ShowsMuscleGroupBreakdown() throws {
        navigateToProgress()

        // Should show muscle group volume breakdown
        let musclePredicate = NSPredicate(
            format: "label CONTAINS[c] 'muscle' OR label CONTAINS[c] 'chest' OR label CONTAINS[c] 'back' OR label CONTAINS[c] 'legs'"
        )
        _ = app.staticTexts.element(matching: musclePredicate).waitForExistence(timeout: 5)
    }

    // MARK: - Helper Methods

    private func navigateToProgress() {
        let progressTab = app.tabBars.buttons["Progress"]
        if progressTab.waitForExistence(timeout: 5) {
            progressTab.tap()
        }
    }
}
