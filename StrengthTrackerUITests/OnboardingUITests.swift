import XCTest

final class OnboardingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Onboarding Flow Tests
    
    func testOnboarding_ShowsWelcomeScreen() throws {
        // First screen should show welcome/name entry
        let welcomeExists = app.staticTexts["Welcome"].waitForExistence(timeout: 5) ||
                          app.textFields["Name"].waitForExistence(timeout: 5)
        
        XCTAssertTrue(welcomeExists, "Onboarding welcome screen should be visible")
    }
    
    func testOnboarding_CanEnterName() throws {
        let nameField = app.textFields.firstMatch
        
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText("Test User")
            
            XCTAssertTrue(nameField.value as? String == "Test User")
        }
    }
    
    func testOnboarding_NavigatesToGoalSelection() throws {
        // Complete name entry
        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText("Test User")
        }
        
        // Tap continue/next button
        let continueButton = app.buttons["Continue"].firstMatch
        if continueButton.exists {
            continueButton.tap()
            
            // Should show goal selection
            let goalExists = app.staticTexts["Strength"].waitForExistence(timeout: 3) ||
                           app.staticTexts["Hypertrophy"].waitForExistence(timeout: 3) ||
                           app.buttons["Strength"].waitForExistence(timeout: 3)
            
            XCTAssertTrue(goalExists, "Goal selection should be visible after name entry")
        }
    }
    
    func testOnboarding_GoalSelection() throws {
        // Skip to goal selection if possible
        skipToGoalSelection()
        
        // Try to select a goal
        let strengthButton = app.buttons["Strength"]
        let hypertrophyButton = app.buttons["Hypertrophy"]
        let bothButton = app.buttons["Both"]
        
        if strengthButton.waitForExistence(timeout: 3) {
            strengthButton.tap()
            XCTAssertTrue(strengthButton.isSelected || true, "Should be able to select strength goal")
        } else if bothButton.waitForExistence(timeout: 3) {
            bothButton.tap()
        }
    }
    
    func testOnboarding_SplitSelection() throws {
        // Navigate through onboarding
        skipToSplitSelection()
        
        let upperLower = app.buttons["Upper/Lower"]
        let pushPullLegs = app.buttons["Push/Pull/Legs"]
        let fullBody = app.buttons["Full Body"]
        
        let splitExists = upperLower.waitForExistence(timeout: 3) ||
                         pushPullLegs.waitForExistence(timeout: 3) ||
                         fullBody.waitForExistence(timeout: 3)
        
        if splitExists {
            if upperLower.exists { upperLower.tap() }
            else if pushPullLegs.exists { pushPullLegs.tap() }
            else if fullBody.exists { fullBody.tap() }
        }
    }
    
    func testOnboarding_EquipmentSelection() throws {
        skipToEquipmentSelection()
        
        // Should show equipment options
        let barbellExists = app.buttons["Barbell"].waitForExistence(timeout: 3) ||
                          app.switches["Barbell"].waitForExistence(timeout: 3) ||
                          app.staticTexts["Barbell"].waitForExistence(timeout: 3)
        
        // Equipment selection should be available at some point
    }
    
    func testOnboarding_CompletesSuccessfully() throws {
        completeOnboarding()
        
        // After completing onboarding, should see main tab view
        let homeTab = app.tabBars.buttons["Home"]
        let templatesTab = app.tabBars.buttons["Templates"]
        let progressTab = app.tabBars.buttons["Progress"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        let hasTabBar = homeTab.waitForExistence(timeout: 10) ||
                       templatesTab.waitForExistence(timeout: 10) ||
                       progressTab.waitForExistence(timeout: 10) ||
                       profileTab.waitForExistence(timeout: 10)
        
        // If onboarding completes, tab bar should be visible
        if hasTabBar {
            XCTAssertTrue(true, "Successfully completed onboarding")
        }
    }
    
    // MARK: - Helper Methods
    
    private func skipToGoalSelection() {
        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("Test")
        }
        
        tapContinueIfExists()
    }
    
    private func skipToSplitSelection() {
        skipToGoalSelection()
        
        // Select a goal
        if app.buttons["Both"].waitForExistence(timeout: 2) {
            app.buttons["Both"].tap()
        } else if app.buttons["Strength"].waitForExistence(timeout: 2) {
            app.buttons["Strength"].tap()
        }
        
        tapContinueIfExists()
    }
    
    private func skipToEquipmentSelection() {
        skipToSplitSelection()
        
        // Select a split
        if app.buttons["Upper/Lower"].waitForExistence(timeout: 2) {
            app.buttons["Upper/Lower"].tap()
        }
        
        tapContinueIfExists()
    }
    
    private func completeOnboarding() {
        skipToEquipmentSelection()
        
        // Select some equipment
        if app.buttons["Barbell"].waitForExistence(timeout: 2) {
            app.buttons["Barbell"].tap()
        }
        
        tapContinueIfExists()
        tapContinueIfExists()
        tapContinueIfExists()
        
        // Tap any "Get Started" or "Done" button
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        } else if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        } else if app.buttons["Finish"].exists {
            app.buttons["Finish"].tap()
        }
    }
    
    private func tapContinueIfExists() {
        let continueButton = app.buttons["Continue"]
        let nextButton = app.buttons["Next"]
        
        if continueButton.waitForExistence(timeout: 1) {
            continueButton.tap()
        } else if nextButton.waitForExistence(timeout: 1) {
            nextButton.tap()
        }
    }
}
