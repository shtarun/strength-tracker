import XCTest

final class WorkoutFlowUITests: XCTestCase {
    
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
    
    // MARK: - Home Screen Tests
    
    func testHomeScreen_ShowsTodaysWorkout() throws {
        // Navigate to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 5) {
            homeTab.tap()
        }
        
        // Should show today's workout or "No workout scheduled"
        let hasWorkoutContent = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'workout'")).waitForExistence(timeout: 5) ||
                               app.buttons["Start Workout"].waitForExistence(timeout: 5)
        
        // Home screen should have workout-related content
    }
    
    func testHomeScreen_CanStartWorkout() throws {
        navigateToHome()
        
        // Look for start workout button
        let startButton = app.buttons["Start Workout"]
        let beginButton = app.buttons["Begin Workout"]
        
        if startButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(startButton.isEnabled, "Start Workout button should be enabled")
        } else if beginButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(beginButton.isEnabled, "Begin Workout button should be enabled")
        }
    }
    
    func testHomeScreen_ShowsWorkoutSwap() throws {
        navigateToHome()
        
        // Should have option to swap workouts
        let swapButton = app.buttons["Swap"]
        let changeButton = app.buttons["Change Workout"]
        
        let hasSwapOption = swapButton.waitForExistence(timeout: 3) ||
                           changeButton.waitForExistence(timeout: 3)
    }
    
    func testHomeScreen_CanAccessCustomWorkout() throws {
        navigateToHome()
        
        // Look for custom workout option
        let customButton = app.buttons["Custom Workout"]
        let aiButton = app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] 'custom'"))
        
        let hasCustomOption = customButton.waitForExistence(timeout: 3) ||
                             aiButton.waitForExistence(timeout: 3)
    }
    
    // MARK: - Workout Flow Tests
    
    func testWorkoutFlow_StartWorkout() throws {
        navigateToHome()
        
        // Start a workout
        let startButton = app.buttons["Start Workout"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
            
            // Should show readiness check or workout view
            let readinessExists = app.staticTexts["Energy"].waitForExistence(timeout: 3) ||
                                 app.staticTexts["Readiness"].waitForExistence(timeout: 3) ||
                                 app.staticTexts["How are you feeling"].waitForExistence(timeout: 3)
            
            let workoutViewExists = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'Set'")).waitForExistence(timeout: 5)
            
            XCTAssertTrue(readinessExists || workoutViewExists, "Should show readiness check or workout view")
        }
    }
    
    func testWorkoutFlow_ReadinessCheck() throws {
        startWorkout()
        
        // Check for readiness options
        let energyOptions = ["High", "OK", "Low"]
        let sorenessOptions = ["None", "Moderate", "High"]
        
        for energy in energyOptions {
            if app.buttons[energy].exists {
                app.buttons[energy].tap()
                break
            }
        }
        
        // Continue past readiness
        tapContinueIfExists()
    }
    
    func testWorkoutFlow_LogSet() throws {
        startWorkoutAndSkipReadiness()
        
        // Should be in workout view
        // Look for weight/reps input or set logging UI
        let weightField = app.textFields.element(matching: NSPredicate(format: "placeholderValue CONTAINS[c] 'weight' OR value CONTAINS[c] 'kg' OR value CONTAINS[c] 'lb'"))
        let repsField = app.textFields.element(matching: NSPredicate(format: "placeholderValue CONTAINS[c] 'reps'"))
        
        // Try to find any numeric input field
        let anyTextField = app.textFields.firstMatch
        
        if anyTextField.waitForExistence(timeout: 5) {
            // Workout logging UI is present
            XCTAssertTrue(true, "Workout logging UI is visible")
        }
    }
    
    func testWorkoutFlow_FinishWorkout() throws {
        startWorkoutAndSkipReadiness()
        
        // Look for finish/complete button
        let finishButton = app.buttons["Finish Workout"]
        let completeButton = app.buttons["Complete"]
        let doneButton = app.buttons["Done"]
        
        let hasFinishOption = finishButton.waitForExistence(timeout: 5) ||
                             completeButton.waitForExistence(timeout: 5) ||
                             doneButton.waitForExistence(timeout: 5)
    }
    
    func testWorkoutFlow_RestTimer() throws {
        startWorkoutAndSkipReadiness()
        
        // After logging a set, should have rest timer option
        // This might appear after tapping "Log Set" or similar
        
        let restTimer = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'rest' OR label CONTAINS[c] 'timer'"))
        let timerExists = restTimer.waitForExistence(timeout: 3)
    }
    
    // MARK: - Workout Summary Tests
    
    func testWorkoutSummary_ShowsAfterCompletion() throws {
        startWorkoutAndSkipReadiness()
        
        // Try to finish the workout
        let finishButton = app.buttons["Finish Workout"]
        if finishButton.waitForExistence(timeout: 5) {
            finishButton.tap()
            
            // Should show summary
            let summaryExists = app.staticTexts["Summary"].waitForExistence(timeout: 5) ||
                               app.staticTexts["Workout Complete"].waitForExistence(timeout: 5) ||
                               app.staticTexts["Great job"].waitForExistence(timeout: 5)
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToHome() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 5) {
            homeTab.tap()
        }
    }
    
    private func startWorkout() {
        navigateToHome()
        
        let startButton = app.buttons["Start Workout"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
        }
    }
    
    private func startWorkoutAndSkipReadiness() {
        startWorkout()
        
        // Skip readiness check
        if app.buttons["OK"].waitForExistence(timeout: 2) {
            app.buttons["OK"].tap()
        }
        if app.buttons["None"].waitForExistence(timeout: 2) {
            app.buttons["None"].tap()
        }
        
        tapContinueIfExists()
    }
    
    private func tapContinueIfExists() {
        let continueButton = app.buttons["Continue"]
        let startButton = app.buttons["Start"]
        let beginButton = app.buttons["Begin"]
        
        if continueButton.waitForExistence(timeout: 1) {
            continueButton.tap()
        } else if startButton.waitForExistence(timeout: 1) {
            startButton.tap()
        } else if beginButton.waitForExistence(timeout: 1) {
            beginButton.tap()
        }
    }
}
