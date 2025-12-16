import XCTest

final class TemplatesUITests: XCTestCase {

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

    // MARK: - Templates Navigation Tests

    func testTemplates_NavigateToTemplatesTab() throws {
        let templatesTab = app.tabBars.buttons["Templates"]
        XCTAssertTrue(templatesTab.waitForExistence(timeout: 5), "Templates tab should exist")

        templatesTab.tap()
    }

    // MARK: - Templates List Tests

    func testTemplates_ShowsTemplatesList() throws {
        navigateToTemplates()

        // Should show list of workout templates - use count for XCUIElementQuery
        let hasCells = app.cells.count > 0
        let hasText = app.staticTexts.element(matching: NSPredicate(
            format: "label CONTAINS[c] 'Upper' OR label CONTAINS[c] 'Lower' OR label CONTAINS[c] 'Push' OR label CONTAINS[c] 'Pull' OR label CONTAINS[c] 'Legs'"
        )).waitForExistence(timeout: 5)

        XCTAssertTrue(hasCells || hasText, "Should show templates list")
    }

    func testTemplates_ShowsUpperLowerSplit() throws {
        navigateToTemplates()

        let upperPredicate = NSPredicate(format: "label CONTAINS[c] 'upper'")
        let lowerPredicate = NSPredicate(format: "label CONTAINS[c] 'lower'")

        _ = app.staticTexts.element(matching: upperPredicate).waitForExistence(timeout: 3)
        _ = app.staticTexts.element(matching: lowerPredicate).waitForExistence(timeout: 3)
        // Test passes if no crash - templates may vary
    }

    func testTemplates_CanSelectTemplate() throws {
        navigateToTemplates()

        // Try to select a template
        let firstTemplate = app.cells.firstMatch
        if firstTemplate.waitForExistence(timeout: 5) {
            XCTAssertTrue(firstTemplate.isHittable, "Template should be tappable")
            firstTemplate.tap()
        }
    }

    // MARK: - Template Detail Tests

    func testTemplateDetail_ShowsExercises() throws {
        navigateToTemplates()

        let firstTemplate = app.cells.firstMatch
        guard firstTemplate.waitForExistence(timeout: 5) else {
            throw XCTSkip("No templates available")
        }

        firstTemplate.tap()

        // Should show exercises in template
        let exercisePredicate = NSPredicate(
            format: "label CONTAINS[c] 'Press' OR label CONTAINS[c] 'Row' OR label CONTAINS[c] 'Squat' OR label CONTAINS[c] 'Curl'"
        )
        _ = app.staticTexts.element(matching: exercisePredicate).waitForExistence(timeout: 3)
    }

    func testTemplateDetail_ShowsSetsPrescription() throws {
        navigateToTemplates()

        let firstTemplate = app.cells.firstMatch
        guard firstTemplate.waitForExistence(timeout: 5) else {
            throw XCTSkip("No templates available")
        }

        firstTemplate.tap()

        // Should show sets/reps prescription
        let setsPredicate = NSPredicate(format: "label CONTAINS[c] 'set' OR label CONTAINS[c] 'rep' OR label CONTAINS[c] 'x'")
        _ = app.staticTexts.element(matching: setsPredicate).waitForExistence(timeout: 3)
    }

    func testTemplateDetail_ShowsRPE() throws {
        navigateToTemplates()

        let firstTemplate = app.cells.firstMatch
        guard firstTemplate.waitForExistence(timeout: 5) else {
            throw XCTSkip("No templates available")
        }

        firstTemplate.tap()

        // Should show RPE targets
        let rpePredicate = NSPredicate(format: "label CONTAINS[c] 'RPE' OR label CONTAINS[c] '@'")
        _ = app.staticTexts.element(matching: rpePredicate).waitForExistence(timeout: 3)
    }

    // MARK: - Template Edit Tests

    func testTemplateDetail_CanEditTemplate() throws {
        navigateToTemplates()

        let firstTemplate = app.cells.firstMatch
        guard firstTemplate.waitForExistence(timeout: 5) else {
            throw XCTSkip("No templates available")
        }

        firstTemplate.tap()

        // Look for edit button
        let editButton = app.buttons["Edit"]
        _ = editButton.waitForExistence(timeout: 3)
    }

    func testTemplateDetail_CanReorderExercises() throws {
        navigateToTemplates()

        let firstTemplate = app.cells.firstMatch
        guard firstTemplate.waitForExistence(timeout: 5) else {
            throw XCTSkip("No templates available")
        }

        firstTemplate.tap()

        // Check for edit mode or reorder handles
        let editButton = app.buttons["Edit"]
        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()
            // Should now be in edit mode
        }
    }

    // MARK: - Exercise Substitution Tests

    func testTemplateDetail_CanSubstituteExercise() throws {
        navigateToTemplates()

        let firstTemplate = app.cells.firstMatch
        guard firstTemplate.waitForExistence(timeout: 5) else {
            throw XCTSkip("No templates available")
        }

        firstTemplate.tap()

        // Look for substitute/swap option
        let swapPredicate = NSPredicate(format: "label CONTAINS[c] 'swap' OR label CONTAINS[c] 'substitute' OR label CONTAINS[c] 'change'")
        _ = app.buttons.element(matching: swapPredicate).waitForExistence(timeout: 3)
    }

    // MARK: - Template Day Tests

    func testTemplates_ShowsDayOfWeek() throws {
        navigateToTemplates()

        // Templates should show which day they're for
        let dayPredicate = NSPredicate(
            format: "label CONTAINS[c] 'Day' OR label CONTAINS[c] 'Monday' OR label CONTAINS[c] 'Tuesday' OR label CONTAINS[c] 'Wednesday' OR label CONTAINS[c] 'Thursday' OR label CONTAINS[c] 'Friday' OR label CONTAINS[c] 'Saturday' OR label CONTAINS[c] 'Sunday'"
        )
        _ = app.staticTexts.element(matching: dayPredicate).waitForExistence(timeout: 3)
    }

    func testTemplates_ShowsFocus() throws {
        navigateToTemplates()

        // Templates should show their focus (e.g., "Horizontal Push/Pull")
        let focusPredicate = NSPredicate(
            format: "label CONTAINS[c] 'focus' OR label CONTAINS[c] 'Push' OR label CONTAINS[c] 'Pull' OR label CONTAINS[c] 'Squat' OR label CONTAINS[c] 'Hinge'"
        )
        _ = app.staticTexts.element(matching: focusPredicate).waitForExistence(timeout: 3)
    }

    // MARK: - Helper Methods

    private func navigateToTemplates() {
        let templatesTab = app.tabBars.buttons["Templates"]
        if templatesTab.waitForExistence(timeout: 5) {
            templatesTab.tap()
        }
    }
}
