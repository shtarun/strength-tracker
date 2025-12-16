# Testing Documentation

This document provides comprehensive documentation for all tests in the Strength Tracker iOS application.

## Table of Contents

- [Test Architecture](#test-architecture)
- [Running Tests](#running-tests)
- [Unit Tests](#unit-tests)
  - [E1RMCalculatorTests](#e1rmcalculatortests)
  - [ExerciseLibraryTests](#exerciselibrarytests)
  - [LLMServiceTests](#llmservicetests)
  - [ModelTests](#modeltests)
  - [OfflineProgressionEngineTests](#offlineprogressionenginetests)
  - [PlateMathCalculatorTests](#platemathcalculatortests)
  - [StallDetectorTests](#stalldetectortests)
  - [SubstitutionGraphTests](#substitutiongraphtests)
  - [TemplateGeneratorTests](#templategeneratortests)
  - [UserProfileTests](#userprofiletests)
  - [WorkoutSessionTests](#workoutsessiontests)
- [UI Tests](#ui-tests)
  - [OnboardingUITests](#onboardinguiTests)
  - [WorkoutFlowUITests](#workoutflowuitests)
  - [ProfileUITests](#profileuitests)
  - [ProgressUITests](#progressuitests)
  - [TemplatesUITests](#templatesuitests)
- [Test Coverage](#test-coverage)
- [Writing New Tests](#writing-new-tests)

---

## Test Architecture

### Why Two Test Folders?

The project follows iOS best practices by separating tests into two distinct targets:

```
StrengthTracker/
├── StrengthTrackerTests/      # Unit Tests (XCTest)
│   ├── E1RMCalculatorTests.swift
│   ├── ExerciseLibraryTests.swift
│   ├── LLMServiceTests.swift
│   ├── ModelTests.swift
│   ├── OfflineProgressionEngineTests.swift
│   ├── PlateMathCalculatorTests.swift
│   ├── StallDetectorTests.swift
│   ├── SubstitutionGraphTests.swift
│   ├── TemplateGeneratorTests.swift
│   ├── UserProfileTests.swift
│   └── WorkoutSessionTests.swift
│
└── StrengthTrackerUITests/    # UI Tests (XCUITest)
    ├── OnboardingUITests.swift
    ├── ProfileUITests.swift
    ├── ProgressUITests.swift
    ├── TemplatesUITests.swift
    └── WorkoutFlowUITests.swift
```

| Aspect | Unit Tests | UI Tests |
|--------|-----------|----------|
| **Framework** | XCTest | XCUITest |
| **Speed** | Fast (milliseconds) | Slow (seconds) |
| **Isolation** | Highly isolated | Full app integration |
| **Purpose** | Test logic & calculations | Test user flows |
| **Dependencies** | Minimal | Requires simulator/device |
| **When to Run** | Every commit | Pre-release, CI/CD |

---

## Running Tests

### Via Xcode

1. **Run All Tests**: `⌘ + U`
2. **Run Single Test**: Click the diamond next to a test method
3. **Run Test File**: Click the diamond next to the class name

### Via Command Line

```bash
# Run all tests
xcodebuild test -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Run only unit tests
xcodebuild test -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:StrengthTrackerTests

# Run only UI tests
xcodebuild test -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:StrengthTrackerUITests

# Run specific test class
xcodebuild test -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:StrengthTrackerTests/E1RMCalculatorTests
```

---

## Unit Tests

### E1RMCalculatorTests

**File:** `StrengthTrackerTests/E1RMCalculatorTests.swift`

Tests the Estimated 1 Rep Max calculator using the Epley formula.

| Test Method | Description |
|-------------|-------------|
| `testCalculate_SingleRep_ReturnsWeight()` | Verifies 1RM equals lifted weight for single rep |
| `testCalculate_FiveReps_CalculatesCorrectly()` | Tests standard 5-rep calculation |
| `testCalculate_TenReps_CalculatesCorrectly()` | Tests 10-rep hypertrophy range |
| `testCalculate_ZeroWeight_ReturnsZero()` | Edge case: zero weight input |
| `testCalculate_ZeroReps_ReturnsZero()` | Edge case: zero reps input |
| `testCalculate_HighReps_StillCalculates()` | Tests high rep ranges (15+) |

**Formula Tested:** `e1RM = weight × (1 + reps/30)`

---

### ExerciseLibraryTests

**File:** `StrengthTrackerTests/ExerciseLibraryTests.swift`

Tests exercise creation, form guidance, and movement pattern categorization.

#### ExerciseLibraryTests Class

| Test Method | Description |
|-------------|-------------|
| `testCreateAllExercises_ReturnsNonEmpty()` | Validates exercise creation with all properties |
| `testExercise_FormGuidance_HasFormGuidance()` | Tests `hasFormGuidance` computed property |
| `testExercise_NoFormGuidance_HasFormGuidanceFalse()` | Tests exercises without form cues |

#### MovementPatternEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testMovementPattern_AllCases()` | Validates all movement patterns exist |
| `testMovementPattern_Identifiable()` | Tests Identifiable conformance |
| `testMovementPattern_RawValues()` | Validates raw string values |

#### EquipmentEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testEquipment_AllCases()` | Validates all equipment types exist |
| `testEquipment_Identifiable()` | Tests Identifiable conformance |
| `testEquipment_IconNames()` | Validates SF Symbol icon mappings |
| `testEquipment_RequiresGym()` | Tests gym requirement property |

#### MuscleEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testMuscle_AllCases()` | Validates all muscle groups exist |
| `testMuscle_MuscleGroup()` | Tests muscle-to-group mapping |
| `testMuscle_Identifiable()` | Tests Identifiable conformance |

---

### LLMServiceTests

**File:** `StrengthTrackerTests/LLMServiceTests.swift`

Tests LLM service integration, context building, and response handling.

| Test Method | Description |
|-------------|-------------|
| `testBuildContext_CreatesValidJSON()` | Tests context serialization |
| `testStallAnalysisResponse_Stalled()` | Tests stall detection response parsing |
| `testStallAnalysisResponse_NotStalled()` | Tests non-stalled response |
| `testStallContext_Codable()` | Tests StallContext encoding/decoding |
| `testTodayPlanResponse_Codable()` | Tests workout plan response parsing |
| `testInsightResponse_Codable()` | Tests insight response parsing |

---

### ModelTests

**File:** `StrengthTrackerTests/ModelTests.swift`

Tests core data models and enums.

#### ExerciseModelTests Class

| Test Method | Description |
|-------------|-------------|
| `testExercise_Creation()` | Tests Exercise model initialization |
| `testExercise_DefaultValues()` | Validates default property values |
| `testExercise_DefaultWeightIncrement()` | Tests weight increment defaults |

#### GoalModelEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testGoal_AllCases()` | Validates strength/hypertrophy/both |
| `testGoal_RawValues()` | Tests display strings |

#### LocationEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testLocation_AllCases()` | Validates gym/home/mixed |
| `testLocation_RawValues()` | Tests display strings |

#### SetTypeEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testSetType_AllCases()` | Validates warmup/working/topSet/backoff |
| `testSetType_RawValues()` | Tests display strings |

#### ReadinessTests Class

| Test Method | Description |
|-------------|-------------|
| `testReadiness_Default()` | Tests default readiness values |
| `testReadiness_ShouldReduceIntensity()` | Tests low energy/high soreness detection |
| `testReadiness_ShouldIncreaseIntensity()` | Tests optimal conditions detection |

#### EnergyLevelEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testEnergyLevel_AllCases()` | Validates low/ok/high levels |

#### SorenessLevelEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testSorenessLevel_AllCases()` | Validates none/mild/high levels |
| `testSorenessLevel_RawValues()` | Tests display strings |

#### LLMProviderTypeEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testLLMProviderType_AllCases()` | Validates offline/openai/claude |
| `testLLMProviderType_DisplayName()` | Tests user-facing names |
| `testLLMProviderType_RequiresAPIKey()` | Tests API key requirements |

---

### OfflineProgressionEngineTests

**File:** `StrengthTrackerTests/OfflineProgressionEngineTests.swift`

Tests the offline progression algorithm for workout recommendations.

| Test Method | Description |
|-------------|-------------|
| `testSuggestProgression_NoHistory_ReturnsConservative()` | Tests first workout suggestions |
| `testSuggestProgression_Progressing_IncreasesWeight()` | Tests weight progression logic |
| `testSuggestProgression_Struggling_ReducesVolume()` | Tests deload detection |
| `testSuggestProgression_Stalled_SuggestsFix()` | Tests plateau breaking suggestions |
| `testCalculateWarmups_ReturnsAscendingWeights()` | Tests warmup set generation |

---

### PlateMathCalculatorTests

**File:** `StrengthTrackerTests/PlateMathCalculatorTests.swift`

Tests barbell plate loading calculations.

| Test Method | Description |
|-------------|-------------|
| `testPlatesPerSide_EmptyBar_ReturnsEmpty()` | Tests bar-only weight |
| `testPlatesPerSide_60kg_TwoTwenties()` | Tests simple plate combination |
| `testPlatesPerSide_100kg_CorrectPlates()` | Tests multi-plate loading |
| `testPlatesPerSide_125kg_CorrectPlates()` | Tests complex combinations |
| `testPlatesPerSide_142_5kg_WithMicroplates()` | Tests fractional plates |
| `testPlatesPerSide_BelowBarWeight_ReturnsNil()` | Edge case: impossible weight |
| `testPlatesPerSide_ImpossibleWeight_ReturnsNil()` | Edge case: unloadable weight |
| `testPlatesPerSide_CustomPlates_UsesAvailable()` | Tests custom plate sets |
| `testPlatesPerSide_OlympicBar_25kg()` | Tests alternate bar weights |
| `testPlatesPerSide_WomensBar_15kg()` | Tests women's bar calculations |
| `testNearestLoadable_ExactWeight_ReturnsSame()` | Tests exact matches |
| `testNearestLoadable_SlightlyOver_RoundsUp()` | Tests rounding up |
| `testNearestLoadable_SlightlyUnder_RoundsDown()` | Tests rounding down |
| `testWarmupWeights_HeavyWeight_MultipleWarmups()` | Tests warmup generation |
| `testLoadingInstruction_ValidWeight_ReturnsInstruction()` | Tests human-readable output |

---

### StallDetectorTests

**File:** `StrengthTrackerTests/StallDetectorTests.swift`

Tests plateau detection and fix suggestions.

#### StallDetectorTests Class

| Test Method | Description |
|-------------|-------------|
| `testStallFix_AllCases()` | Validates deload/repRange/variation/weightJump |
| `testStallFix_RawValues()` | Tests internal identifiers |
| `testStallFix_DisplayNames()` | Tests user-facing names |
| `testStallFix_Icons()` | Tests SF Symbol mappings |

#### StallAnalysisResponseTests Class

| Test Method | Description |
|-------------|-------------|
| `testStallAnalysisResponse_NotStalled()` | Tests non-stalled response |
| `testStallAnalysisResponse_Stalled()` | Tests stalled response with fix |
| `testStallAnalysisResponse_Codable()` | Tests JSON encoding/decoding |

#### SessionHistoryContextTests Class

| Test Method | Description |
|-------------|-------------|
| `testSessionHistoryContext_Creation()` | Tests context initialization |
| `testSessionHistoryContext_OptionalRPE()` | Tests nil RPE handling |

#### StallE1RMCalculationTests Class

| Test Method | Description |
|-------------|-------------|
| `testE1RMCalculation_UsedForStallDetection()` | Tests e1RM in stall context |
| `testProgressionDetection_IncreasingE1RM()` | Tests progression detection |
| `testStallDetection_FlatE1RM()` | Tests plateau detection |
| `testStallDetection_DecreasingE1RM()` | Tests regression detection |

---

### SubstitutionGraphTests

**File:** `StrengthTrackerTests/SubstitutionGraphTests.swift`

Tests exercise substitution recommendations.

| Test Method | Description |
|-------------|-------------|
| `testFindSubstitutes_BenchPress_ReturnsAlternatives()` | Tests push substitutions |
| `testFindSubstitutes_Squat_ReturnsAlternatives()` | Tests squat substitutions |
| `testFindSubstitutes_UnknownExercise_ReturnsEmpty()` | Edge case handling |
| `testFindSubstitutes_WithEquipmentFilter_FiltersResults()` | Tests equipment filtering |
| `testSubstitutionScore_SamePattern_HighScore()` | Tests scoring algorithm |

#### SplitSubstitutionEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testSplit_AllCases()` | Validates all split types |
| `testSplit_DaysPerWeek()` | Tests day frequency |
| `testSplit_RawValues()` | Tests display strings |

---

### TemplateGeneratorTests

**File:** `StrengthTrackerTests/TemplateGeneratorTests.swift`

Tests workout template creation.

#### WorkoutTemplateModelTests Class

| Test Method | Description |
|-------------|-------------|
| `testWorkoutTemplate_Creation()` | Tests template initialization |
| `testWorkoutTemplate_DefaultValues()` | Validates defaults |
| `testWorkoutTemplate_WithExercises()` | Tests exercise list handling |

#### ExerciseTemplateTests Class

| Test Method | Description |
|-------------|-------------|
| `testExerciseTemplate_Creation()` | Tests template initialization |
| `testExerciseTemplate_WithDefaultPrescription()` | Tests default prescription |
| `testExerciseTemplate_StrengthPrescription()` | Tests strength config |
| `testExerciseTemplate_HypertrophyPrescription()` | Tests hypertrophy config |
| `testExerciseTemplate_Optional()` | Tests optional exercises |

#### PrescriptionTests Class

| Test Method | Description |
|-------------|-------------|
| `testPrescription_Default()` | Tests default values |
| `testPrescription_Strength()` | Tests strength preset |
| `testPrescription_Hypertrophy()` | Tests hypertrophy preset |
| `testPrescription_CustomValues()` | Tests custom configuration |

---

### UserProfileTests

**File:** `StrengthTrackerTests/UserProfileTests.swift`

Tests user profile and preferences.

#### UserProfileTests Class

| Test Method | Description |
|-------------|-------------|
| `testUserProfile_DefaultValues()` | Tests initialization defaults |
| `testUserProfile_HasValidAPIKey_Empty()` | Tests empty key validation |
| `testUserProfile_HasValidAPIKey_Whitespace()` | Tests whitespace handling |
| `testUserProfile_HasValidAPIKey_Valid()` | Tests valid key detection |

#### AppearanceModeTests Class

| Test Method | Description |
|-------------|-------------|
| `testAppearanceMode_AllCases()` | Validates auto/light/dark |
| `testAppearanceMode_ColorScheme()` | Tests SwiftUI ColorScheme mapping |
| `testAppearanceMode_Identifiable()` | Tests Identifiable conformance |

#### GoalEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testGoal_AllCases()` | Validates all goal types |
| `testGoal_Identifiable()` | Tests Identifiable conformance |

#### SplitEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testSplit_AllCases()` | Validates all split types |

#### UnitSystemTests Class

| Test Method | Description |
|-------------|-------------|
| `testUnitSystem_Metric_FormatWeight()` | Tests kg formatting |
| `testUnitSystem_Imperial_FormatWeight()` | Tests lbs formatting |

---

### WorkoutSessionTests

**File:** `StrengthTrackerTests/WorkoutSessionTests.swift`

Tests workout sessions and sets.

#### ReadinessEnumTests Class

| Test Method | Description |
|-------------|-------------|
| `testReadiness_DefaultValue()` | Tests default readiness |
| `testReadiness_ShouldReduceIntensity_LowEnergy()` | Tests fatigue detection |
| `testReadiness_ShouldReduceIntensity_HighSoreness()` | Tests soreness detection |
| `testReadiness_ShouldIncreaseIntensity()` | Tests optimal detection |

#### SetTypeTests Class

| Test Method | Description |
|-------------|-------------|
| `testSetType_AllCases()` | Validates all set types |
| `testSetType_RawValues()` | Tests display strings |

#### WorkoutSetE1RMTests Class

| Test Method | Description |
|-------------|-------------|
| `testE1RM_CalculatedValue()` | Tests e1RM calculation |
| `testE1RM_SingleRep()` | Tests 1RM accuracy |
| `testE1RM_HigherReps_HigherE1RM()` | Tests rep progression |

#### SetHistoryTests Class

| Test Method | Description |
|-------------|-------------|
| `testSetHistory_FromWorkoutSet()` | Tests history creation |
| `testSetHistory_Codable()` | Tests JSON serialization |
| `testSetHistory_E1RMCalculation()` | Tests e1RM in history |

---

## UI Tests

UI tests use XCUITest framework to simulate user interactions with the app.

### OnboardingUITests

**File:** `StrengthTrackerUITests/OnboardingUITests.swift`

Tests the new user onboarding flow.

| Test Method | Description |
|-------------|-------------|
| `testOnboarding_ShowsWelcomeScreen()` | Verifies welcome screen appears |
| `testOnboarding_CanEnterName()` | Tests name input field |
| `testOnboarding_NavigatesToGoalSelection()` | Tests flow to goal selection |
| `testOnboarding_CanSelectGoal()` | Tests goal button interaction |
| `testOnboarding_NavigatesToSplitSelection()` | Tests flow to split selection |
| `testOnboarding_CanSelectSplit()` | Tests split button interaction |
| `testOnboarding_NavigatesToEquipmentSelection()` | Tests flow to equipment |
| `testOnboarding_CompletesOnboarding()` | Tests full flow completion |

---

### WorkoutFlowUITests

**File:** `StrengthTrackerUITests/WorkoutFlowUITests.swift`

Tests the workout logging user flow.

| Test Method | Description |
|-------------|-------------|
| `testWorkout_HomeShowsTodaysWorkout()` | Verifies home screen workout display |
| `testWorkout_CanStartWorkout()` | Tests workout initiation |
| `testWorkout_ReadinessCheckAppears()` | Tests readiness sheet |
| `testWorkout_CanSelectReadinessEnergy()` | Tests energy selection |
| `testWorkout_CanLogSet()` | Tests set logging |
| `testWorkout_RestTimerAppears()` | Tests rest timer display |
| `testWorkout_CanCompleteWorkout()` | Tests workout completion |
| `testWorkout_SummarySheetAppears()` | Tests summary display |

---

### ProfileUITests

**File:** `StrengthTrackerUITests/ProfileUITests.swift`

Tests profile and settings screens.

| Test Method | Description |
|-------------|-------------|
| `testProfile_NavigatesToProfile()` | Tests tab navigation |
| `testProfile_ShowsUserName()` | Verifies name display |
| `testProfile_ShowsSettings()` | Tests settings visibility |
| `testProfile_CanChangeAppearance()` | Tests appearance toggle |
| `testProfile_CanAccessEquipmentSettings()` | Tests equipment navigation |
| `testProfile_CanAccessAPISettings()` | Tests API settings navigation |
| `testProfile_ResetDataShowsConfirmation()` | Tests reset confirmation |

---

### ProgressUITests

**File:** `StrengthTrackerUITests/ProgressUITests.swift`

Tests the progress tracking screens.

| Test Method | Description |
|-------------|-------------|
| `testProgress_NavigatesToProgress()` | Tests tab navigation |
| `testProgress_ShowsOverviewTab()` | Tests overview visibility |
| `testProgress_CanSwitchToLiftsTab()` | Tests tab switching |
| `testProgress_ShowsExerciseList()` | Tests exercise list |
| `testProgress_CanSelectExercise()` | Tests exercise selection |
| `testProgress_ShowsExerciseDetail()` | Tests detail view |
| `testProgress_ShowsChart()` | Tests chart visibility |
| `testProgress_CanAccessFormTips()` | Tests form tips access |

---

### TemplatesUITests

**File:** `StrengthTrackerUITests/TemplatesUITests.swift`

Tests the template management screens.

| Test Method | Description |
|-------------|-------------|
| `testTemplates_NavigateToTemplatesTab()` | Tests tab navigation |
| `testTemplates_ShowsTemplatesList()` | Tests list visibility |
| `testTemplates_CanSelectTemplate()` | Tests template selection |
| `testTemplates_ShowsTemplateDetail()` | Tests detail view |
| `testTemplates_ShowsExercisesInTemplate()` | Tests exercise list |
| `testTemplates_ShowsSetsAndRPE()` | Tests prescription display |
| `testTemplates_CanEditTemplate()` | Tests edit functionality |
| `testTemplates_CanSubstituteExercise()` | Tests substitution access |

---

## Test Coverage

### Current Coverage by Module

| Module | Coverage | Key Areas |
|--------|----------|-----------|
| **Utilities** | ~95% | E1RM, PlateMath calculators |
| **Models** | ~85% | All enums, Readiness, Prescription |
| **Services** | ~80% | StallDetector, SubstitutionGraph |
| **Agent** | ~70% | LLMService, OfflineProgression |
| **Views** | ~60% | Via UI tests |

### Running Coverage Reports

```bash
xcodebuild test -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -enableCodeCoverage YES
```

---

## Writing New Tests

### Unit Test Template

```swift
import XCTest
@testable import StrengthTracker

final class MyFeatureTests: XCTestCase {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        // Setup code
    }
    
    override func tearDownWithError() throws {
        // Cleanup code
    }
    
    // MARK: - Tests
    
    func testMyFeature_GivenCondition_ExpectedResult() {
        // Given
        let input = ...
        
        // When
        let result = myFunction(input)
        
        // Then
        XCTAssertEqual(result, expectedValue)
    }
}
```

### UI Test Template

```swift
import XCTest

final class MyFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testMyFlow_Action_ExpectedOutcome() throws {
        // Navigate
        let button = app.buttons["My Button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        
        // Act
        button.tap()
        
        // Assert
        let result = app.staticTexts["Expected Text"]
        XCTAssertTrue(result.exists)
    }
}
```

### Best Practices

1. **Naming Convention**: `test<Feature>_<Condition>_<ExpectedResult>()`
2. **Arrange-Act-Assert**: Structure tests with Given/When/Then
3. **One Assertion Per Test**: Focus each test on one behavior
4. **Avoid Test Interdependence**: Tests should run in any order
5. **Use Descriptive Failure Messages**: Help debugging
6. **Mock External Dependencies**: Keep tests isolated

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      
      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project StrengthTracker/StrengthTracker.xcodeproj \
            -scheme StrengthTracker \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:StrengthTrackerTests
      
      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project StrengthTracker/StrengthTracker.xcodeproj \
            -scheme StrengthTracker \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:StrengthTrackerUITests
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Tests not discovered | Clean build folder (⌘⇧K), rebuild |
| UI tests timing out | Increase `waitForExistence` timeout |
| SwiftData tests failing | Use in-memory container for isolation |
| Flaky UI tests | Add explicit waits, avoid animations |

### Debug Tips

1. **Print statements**: Use `print()` in tests for debugging
2. **Breakpoints**: Set breakpoints in test code
3. **UI Recording**: Use Xcode's UI test recording feature
4. **Test Navigator**: Use ⌘6 to see all tests

---

*Last updated: December 2025*
