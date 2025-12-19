# Testing Documentation

This document describes the unit testing strategy and implementation for the Strength Tracker iOS application.

## Overview

The test suite contains comprehensive unit tests for all core functionality. Tests are designed to be fast and reliable in CI environments.

**Note:** Since this is an iOS app, tests run on iOS Simulator. However, all tests are pure unit tests that don't require device-specific features, making them fast and consistent.

## Test Structure

```
StrengthTrackerTests/
├── E1RMCalculatorTests.swift      # Strength estimation formulas
├── PlateMathCalculatorTests.swift # Barbell/dumbbell loading calculations
├── ExerciseMatcherTests.swift     # Fuzzy exercise name matching
├── ModelTests.swift               # Core model types and enums
├── StallDetectorTests.swift       # Plateau detection algorithm
├── OfflineProgressionEngineTests.swift # Rule-based workout planning
├── SubstitutionGraphTests.swift   # Exercise substitution logic
├── LLMServiceTests.swift          # LLM request/response types
├── DataTransferServiceTests.swift # Export/import functionality
├── WorkoutPlanTests.swift         # Plan and periodization logic
├── WorkoutSessionTests.swift      # Session analysis and tracking
└── CustomWorkoutTests.swift       # Custom workout generation
```

## Running Tests

### Local Development

Run all unit tests:
```bash
xcodebuild test \
  -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StrengthTrackerTests \
  CODE_SIGNING_ALLOWED=NO
```

Run a specific test file:
```bash
xcodebuild test \
  -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StrengthTrackerTests/E1RMCalculatorTests \
  CODE_SIGNING_ALLOWED=NO
```

### Xcode IDE

1. Open `StrengthTracker.xcodeproj` in Xcode
2. Select the `StrengthTracker` scheme
3. Press `Cmd + U` to run all tests
4. Or use the Test Navigator (`Cmd + 6`) to run individual tests

## Test Categories

### 1. Utility Tests (Pure Functions)

**E1RMCalculatorTests** - Tests for estimated one-rep max calculations:
- Epley formula: `e1RM = weight × (1 + reps/30)`
- Brzycki formula: `e1RM = weight × (36 / (37 - reps))`
- Edge cases: zero reps, single rep, high reps
- Round-trip verification

**PlateMathCalculatorTests** - Tests for barbell and dumbbell loading:
- Plate calculation per side (greedy algorithm)
- Warmup weight generation
- Nearest loadable weight
- Dumbbell matching and progression

### 2. Model Tests

**ModelTests** - Tests for core data types:
- `Readiness` struct: computed properties, Codable conformance
- Enums: `Goal`, `SetType`, `Equipment`, `Muscle`, `MovementPattern`
- Response types: `StallAnalysisResponse`, `InsightResponse`, etc.
- Context types for LLM communication

### 3. Service Tests

**ExerciseMatcherTests** - Fuzzy matching algorithm:
- Exact match (case-insensitive)
- Contains matching
- Word-based matching
- Prefix stripping (barbell, dumbbell, etc.)
- Synonym recognition (OHP → Overhead Press, RDL → Romanian Deadlift)

**StallDetectorTests** - Plateau detection:
- High RPE stall → deload suggestion
- Low rep stall → rep range change
- Mid rep stall → variation suggestion
- Progress detection (no false positives)

**SubstitutionGraphTests** - Exercise substitution:
- Equipment-based filtering
- Movement pattern matching
- Pain flag awareness

**OfflineProgressionEngineTests** - Rule-based planning:
- Warmup generation
- Top set calculation with progression
- Readiness adjustments
- Time constraint handling
- Pain flag substitutions

### 4. Business Logic Tests

**LLMServiceTests** - Request/response structures:
- `CoachContext` encoding/decoding
- `TodayPlanResponse` structure
- `CustomWorkoutRequest/Response` handling

**DataTransferServiceTests** - Export/import:
- JSON serialization
- Data integrity preservation
- Version compatibility

**WorkoutPlanTests** - Plan structure:
- Week types (regular, deload, peak, test)
- Split patterns (Upper/Lower, PPL, Full Body)
- Generated plan structure

**WorkoutSessionTests** - Session analysis:
- Volume calculations
- E1RM tracking
- Set analysis (target hit, RPE deviation)

**CustomWorkoutTests** - Custom workout generation:
- Request/response validation
- Reps range parsing
- Equipment filtering
- Duration estimation

## Design Principles

### Fast Unit Tests

All tests are designed to run quickly without requiring device-specific features:

1. **Pure function testing**: Utilities like `E1RMCalculator` and `PlateMathCalculator` are tested directly without any UI or persistence layer.

2. **Context-based testing**: Services like `StallDetector` and `OfflineProgressionEngine` accept context objects (e.g., `StallContext`, `CoachContext`) instead of SwiftData models, allowing tests without a model container.

3. **Codable verification**: All data transfer objects are tested for JSON encode/decode round-trips.

4. **No SwiftData dependencies**: Tests use lightweight test data structures instead of `@Model` types.

### Test Independence

Each test is independent and can run in any order:
- No shared state between tests
- Test data is created inline using helper methods
- No database or file system dependencies

### Realistic Test Data

Tests use realistic fitness data:
- Actual exercise names and weight progressions
- Realistic RPE ranges and rep schemes
- Common stall scenarios from real training

## Adding New Tests

### For Pure Functions

```swift
func testNewCalculation() {
    let result = MyCalculator.calculate(input: someValue)
    XCTAssertEqual(result, expectedValue, accuracy: 0.001)
}
```

### For Services (Actor-based)

```swift
func testServiceBehavior() async {
    let service = MyService.shared
    let context = createTestContext()

    let result = await service.process(context: context)

    XCTAssertTrue(result.isValid)
}
```

### For Codable Types

```swift
func testTypeCodable() throws {
    let original = MyType(value: "test")

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(MyType.self, from: encoded)

    XCTAssertEqual(decoded, original)
}
```

## CI Integration

The GitHub Actions workflow runs tests on every push and pull request:

```yaml
unit-tests:
  name: Unit Tests
  runs-on: macos-14
  steps:
    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -project StrengthTracker.xcodeproj \
          -scheme StrengthTracker \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
          -only-testing:StrengthTrackerTests \
          CODE_SIGNING_ALLOWED=NO
```

### Build Order

1. **Unit Tests** - Must pass first
2. **Build** - iOS app build for simulator (depends on tests passing)
3. **Lint** - SwiftLint static analysis (runs in parallel, can fail without blocking)

## Test Coverage Goals

| Category | Target Coverage |
|----------|----------------|
| Utilities (E1RM, PlateMath) | 95%+ |
| Model Codable conformance | 100% |
| Service core logic | 80%+ |
| Edge cases | All documented |

## Troubleshooting

### Tests Not Running

1. Ensure the test target is included in the scheme:
   - Edit Scheme → Test → Add `StrengthTrackerTests`

2. Check that source files are included in the test target:
   - Select file → File Inspector → Target Membership

### Test Timeouts

Async tests use default timeouts. For long-running operations:
```swift
func testLongOperation() async {
    let expectation = XCTestExpectation(description: "Long operation")
    // ... async work
    await fulfillment(of: [expectation], timeout: 10.0)
}
```

### SwiftData in Tests

If you need to test SwiftData models in the future:
1. Create an in-memory model container
2. Use `ModelConfiguration(isStoredInMemoryOnly: true)`
3. Ensure cleanup in `tearDown()`

## Contributing

When adding new features:

1. Write tests first (TDD approach recommended)
2. Ensure tests run on macOS (no simulator)
3. Use realistic test data
4. Document any new test patterns
5. Update this documentation as needed
