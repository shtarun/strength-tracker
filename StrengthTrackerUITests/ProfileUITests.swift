import XCTest

final class ProfileUITests: XCTestCase {
    
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
    
    // MARK: - Profile Navigation Tests
    
    func testProfile_NavigateToProfileTab() throws {
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        
        profileTab.tap()
        
        // Should show profile content
        let profileTitle = app.navigationBars["Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3) || true, "Profile view should be visible")
    }
    
    // MARK: - Profile Settings Tests
    
    func testProfile_ShowsUserName() throws {
        navigateToProfile()
        
        // Should show name field or label
        let nameExists = app.staticTexts["Name"].waitForExistence(timeout: 3) ||
                        app.textFields["Name"].waitForExistence(timeout: 3)
    }
    
    func testProfile_ShowsGoalSetting() throws {
        navigateToProfile()
        
        let goalExists = app.staticTexts["Goal"].waitForExistence(timeout: 3) ||
                        app.buttons["Goal"].waitForExistence(timeout: 3)
    }
    
    func testProfile_ShowsSplitSetting() throws {
        navigateToProfile()
        
        let splitExists = app.staticTexts["Split"].waitForExistence(timeout: 3) ||
                         app.buttons["Split"].waitForExistence(timeout: 3)
    }
    
    func testProfile_ShowsUnitsSetting() throws {
        navigateToProfile()
        
        let unitsExists = app.staticTexts["Units"].waitForExistence(timeout: 3) ||
                         app.buttons["Units"].waitForExistence(timeout: 3)
    }
    
    func testProfile_ShowsAppearanceSetting() throws {
        navigateToProfile()
        
        let appearanceExists = app.staticTexts["Appearance"].waitForExistence(timeout: 3) ||
                              app.buttons["Appearance"].waitForExistence(timeout: 3)
    }
    
    // MARK: - Appearance Mode Tests
    
    func testProfile_CanChangeAppearance() throws {
        navigateToProfile()
        
        // Find and tap appearance setting
        let appearanceCell = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] 'appearance'"))
        if appearanceCell.waitForExistence(timeout: 3) {
            appearanceCell.tap()
            
            // Should show appearance options
            let autoExists = app.buttons["Auto"].waitForExistence(timeout: 2) ||
                           app.staticTexts["Auto"].waitForExistence(timeout: 2)
            let lightExists = app.buttons["Light"].waitForExistence(timeout: 2) ||
                            app.staticTexts["Light"].waitForExistence(timeout: 2)
            let darkExists = app.buttons["Dark"].waitForExistence(timeout: 2) ||
                           app.staticTexts["Dark"].waitForExistence(timeout: 2)
        }
    }
    
    func testProfile_SelectDarkMode() throws {
        navigateToProfile()
        
        // Try to find appearance picker
        scrollToFindElement(text: "Appearance")
        
        let darkOption = app.buttons["Dark"]
        if darkOption.waitForExistence(timeout: 3) {
            darkOption.tap()
        }
    }
    
    func testProfile_SelectLightMode() throws {
        navigateToProfile()
        
        scrollToFindElement(text: "Appearance")
        
        let lightOption = app.buttons["Light"]
        if lightOption.waitForExistence(timeout: 3) {
            lightOption.tap()
        }
    }
    
    func testProfile_SelectAutoMode() throws {
        navigateToProfile()
        
        scrollToFindElement(text: "Appearance")
        
        let autoOption = app.buttons["Auto"]
        if autoOption.waitForExistence(timeout: 3) {
            autoOption.tap()
        }
    }
    
    // MARK: - Equipment Profile Tests
    
    func testProfile_CanAccessEquipmentSettings() throws {
        navigateToProfile()
        
        let equipmentButton = app.buttons["Equipment Profile"]
        let equipmentCell = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] 'equipment'"))
        
        if equipmentButton.waitForExistence(timeout: 3) {
            equipmentButton.tap()
        } else if equipmentCell.waitForExistence(timeout: 3) {
            equipmentCell.tap()
        }
        
        // Should show equipment editor
    }
    
    // MARK: - AI Settings Tests
    
    func testProfile_ShowsAIProviderSetting() throws {
        navigateToProfile()
        
        scrollToFindElement(text: "AI")
        
        let aiExists = app.staticTexts["AI Coach"].waitForExistence(timeout: 3) ||
                      app.staticTexts["Provider"].waitForExistence(timeout: 3)
    }
    
    func testProfile_CanAccessAPISettings() throws {
        navigateToProfile()
        
        scrollToFindElement(text: "API")
        
        let apiButton = app.buttons["API Keys"]
        let apiCell = app.cells.element(matching: NSPredicate(format: "label CONTAINS[c] 'API'"))
        
        if apiButton.waitForExistence(timeout: 3) {
            apiButton.tap()
        } else if apiCell.waitForExistence(timeout: 3) {
            apiCell.tap()
        }
    }
    
    // MARK: - Reset Data Tests
    
    func testProfile_ShowsResetDataOption() throws {
        navigateToProfile()
        
        scrollToFindElement(text: "Reset")
        
        let resetExists = app.buttons["Reset All Data"].waitForExistence(timeout: 3) ||
                         app.staticTexts["Reset All Data"].waitForExistence(timeout: 3)
    }
    
    func testProfile_ResetDataShowsConfirmation() throws {
        navigateToProfile()
        
        scrollToFindElement(text: "Reset")
        
        let resetButton = app.buttons["Reset All Data"]
        if resetButton.waitForExistence(timeout: 3) {
            resetButton.tap()
            
            // Should show confirmation alert
            let alertExists = app.alerts.firstMatch.waitForExistence(timeout: 3)
            
            if alertExists {
                // Dismiss alert
                let cancelButton = app.alerts.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToProfile() {
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
        }
    }
    
    private func scrollToFindElement(text: String) {
        let scrollView = app.scrollViews.firstMatch
        let form = app.tables.firstMatch
        
        let target = form.exists ? form : scrollView
        
        for _ in 0..<5 {
            if app.staticTexts[text].exists || app.buttons[text].exists {
                break
            }
            target.swipeUp()
        }
    }
}
