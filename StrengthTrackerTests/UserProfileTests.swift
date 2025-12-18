import XCTest
@testable import StrengthTracker

final class UserProfileTests: XCTestCase {
    
    // MARK: - Creation Tests
    
    func testUserProfile_DefaultValues() {
        let profile = UserProfile()
        
        XCTAssertEqual(profile.name, "")
        XCTAssertEqual(profile.goal, .both)
        XCTAssertEqual(profile.daysPerWeek, 4)
        XCTAssertEqual(profile.preferredSplit, .upperLower)
        XCTAssertFalse(profile.rpeFamiliarity)
        XCTAssertEqual(profile.defaultRestTime, 180)
        XCTAssertEqual(profile.unitSystem, .metric)
        XCTAssertEqual(profile.preferredLLMProvider, .offline)
        XCTAssertNil(profile.claudeAPIKey)
        XCTAssertNil(profile.openAIAPIKey)
        XCTAssertEqual(profile.appearanceMode, .auto)
        XCTAssertTrue(profile.showYouTubeLinks) // Default is true
        XCTAssertEqual(profile.activeDaysGoal, 4)
    }
    
    func testUserProfile_CustomValues() {
        let profile = UserProfile(
            name: "John",
            goal: .strength,
            daysPerWeek: 5,
            preferredSplit: .ppl,
            rpeFamiliarity: true,
            defaultRestTime: 240,
            unitSystem: .imperial,
            preferredLLMProvider: .claude,
            claudeAPIKey: "test-key",
            appearanceMode: .dark,
            activeDaysGoal: 6
        )
        
        XCTAssertEqual(profile.name, "John")
        XCTAssertEqual(profile.goal, .strength)
        XCTAssertEqual(profile.daysPerWeek, 5)
        XCTAssertEqual(profile.preferredSplit, .ppl)
        XCTAssertTrue(profile.rpeFamiliarity)
        XCTAssertEqual(profile.defaultRestTime, 240)
        XCTAssertEqual(profile.unitSystem, .imperial)
        XCTAssertEqual(profile.preferredLLMProvider, .claude)
        XCTAssertEqual(profile.claudeAPIKey, "test-key")
        XCTAssertEqual(profile.appearanceMode, .dark)
        XCTAssertEqual(profile.activeDaysGoal, 6)
    }
    
    // MARK: - API Key Tests
    
    func testActiveAPIKey_Claude() {
        let profile = UserProfile(
            preferredLLMProvider: .claude,
            claudeAPIKey: "claude-key"
        )
        
        XCTAssertEqual(profile.activeAPIKey, "claude-key")
    }
    
    func testActiveAPIKey_OpenAI() {
        let profile = UserProfile(
            preferredLLMProvider: .openai,
            openAIAPIKey: "openai-key"
        )
        
        XCTAssertEqual(profile.activeAPIKey, "openai-key")
    }
    
    func testActiveAPIKey_Offline() {
        let profile = UserProfile(
            preferredLLMProvider: .offline
        )
        
        XCTAssertNil(profile.activeAPIKey)
    }
    
    func testHasValidAPIKey_OfflineAlwaysTrue() {
        let profile = UserProfile(preferredLLMProvider: .offline)
        
        XCTAssertTrue(profile.hasValidAPIKey)
    }
    
    func testHasValidAPIKey_ClaudeWithKey() {
        let profile = UserProfile(
            preferredLLMProvider: .claude,
            claudeAPIKey: "valid-key"
        )
        
        XCTAssertTrue(profile.hasValidAPIKey)
    }
    
    func testHasValidAPIKey_ClaudeWithoutKey() {
        let profile = UserProfile(
            preferredLLMProvider: .claude,
            claudeAPIKey: nil
        )
        
        XCTAssertFalse(profile.hasValidAPIKey)
    }
    
    func testHasValidAPIKey_ClaudeWithEmptyKey() {
        let profile = UserProfile(
            preferredLLMProvider: .claude,
            claudeAPIKey: ""
        )
        
        XCTAssertFalse(profile.hasValidAPIKey)
    }
    
    // MARK: - Appearance Mode Tests
    
    func testAppearanceMode_Auto() {
        let profile = UserProfile(appearanceMode: .auto)
        XCTAssertEqual(profile.appearanceMode, .auto)
    }
    
    func testAppearanceMode_Light() {
        let profile = UserProfile(appearanceMode: .light)
        XCTAssertEqual(profile.appearanceMode, .light)
    }
    
    func testAppearanceMode_Dark() {
        let profile = UserProfile(appearanceMode: .dark)
        XCTAssertEqual(profile.appearanceMode, .dark)
    }
    
    // MARK: - YouTube Links Setting Tests
    
    func testShowYouTubeLinks_DefaultTrue() {
        let profile = UserProfile()
        XCTAssertTrue(profile.showYouTubeLinks)
    }
    
    func testShowYouTubeLinks_CanBeDisabled() {
        let profile = UserProfile(showYouTubeLinks: false)
        XCTAssertFalse(profile.showYouTubeLinks)
    }
    
    func testShowYouTubeLinks_CanBeToggled() {
        let profile = UserProfile()
        XCTAssertTrue(profile.showYouTubeLinks)
        
        profile.showYouTubeLinks = false
        XCTAssertFalse(profile.showYouTubeLinks)
        
        profile.showYouTubeLinks = true
        XCTAssertTrue(profile.showYouTubeLinks)
    }
    
    // MARK: - Active Days Goal Tests
    
    func testActiveDaysGoal_Update() {
        let profile = UserProfile()
        XCTAssertEqual(profile.activeDaysGoal, 4)
        
        profile.activeDaysGoal = 6
        XCTAssertEqual(profile.activeDaysGoal, 6)
        
        profile.activeDaysGoal = 2
        XCTAssertEqual(profile.activeDaysGoal, 2)
    }
}

// MARK: - Appearance Mode Enum Tests

final class AppearanceModeTests: XCTestCase {
    
    func testAppearanceMode_AllCases() {
        XCTAssertEqual(AppearanceMode.allCases.count, 3)
        XCTAssertTrue(AppearanceMode.allCases.contains(.auto))
        XCTAssertTrue(AppearanceMode.allCases.contains(.light))
        XCTAssertTrue(AppearanceMode.allCases.contains(.dark))
    }
    
    func testAppearanceMode_RawValues() {
        XCTAssertEqual(AppearanceMode.auto.rawValue, "Auto")
        XCTAssertEqual(AppearanceMode.light.rawValue, "Light")
        XCTAssertEqual(AppearanceMode.dark.rawValue, "Dark")
    }
    
    func testAppearanceMode_Icons() {
        XCTAssertEqual(AppearanceMode.auto.icon, "circle.lefthalf.filled")
        XCTAssertEqual(AppearanceMode.light.icon, "sun.max.fill")
        XCTAssertEqual(AppearanceMode.dark.icon, "moon.fill")
    }
    
    func testAppearanceMode_ColorScheme() {
        XCTAssertNil(AppearanceMode.auto.colorScheme)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }
    
    func testAppearanceMode_Identifiable() {
        XCTAssertEqual(AppearanceMode.auto.id, "Auto")
        XCTAssertEqual(AppearanceMode.light.id, "Light")
        XCTAssertEqual(AppearanceMode.dark.id, "Dark")
    }
}

// MARK: - Goal Enum Tests

final class GoalEnumTests: XCTestCase {
    
    func testGoal_AllCases() {
        XCTAssertEqual(Goal.allCases.count, 3)
        XCTAssertTrue(Goal.allCases.contains(.strength))
        XCTAssertTrue(Goal.allCases.contains(.hypertrophy))
        XCTAssertTrue(Goal.allCases.contains(.both))
    }
    
    func testGoal_Identifiable() {
        XCTAssertEqual(Goal.strength.id, Goal.strength.rawValue)
    }
}

// MARK: - Split Enum Tests (UserProfile)

final class SplitProfileEnumTests: XCTestCase {
    
    func testSplit_AllCases() {
        let splits = Split.allCases
        XCTAssertTrue(splits.contains(.upperLower))
        XCTAssertTrue(splits.contains(.ppl))
        XCTAssertTrue(splits.contains(.fullBody))
        XCTAssertTrue(splits.contains(.custom))
    }
}

// MARK: - Unit System Tests

final class UnitSystemTests: XCTestCase {
    
    func testUnitSystem_Metric_FormatWeight() {
        let metric = UnitSystem.metric
        let formatted = metric.formatWeight(100.0)
        
        XCTAssertTrue(formatted.contains("kg"))
    }
    
    func testUnitSystem_Imperial_FormatWeight() {
        let imperial = UnitSystem.imperial
        let formatted = imperial.formatWeight(225.0)
        
        XCTAssertTrue(formatted.contains("lb"))
    }
}
