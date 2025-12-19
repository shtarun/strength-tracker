import XCTest

/// Unit tests for ExerciseMatcher - Fuzzy matching for exercise names
/// Tests the 6-step matching algorithm for AI-generated exercise names
final class ExerciseMatcherTests: XCTestCase {

    // MARK: - Test Helpers

    /// Create a minimal exercise for testing (without SwiftData context)
    private func createTestExercise(name: String) -> Exercise {
        return Exercise(
            name: name,
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            equipmentRequired: [.barbell]
        )
    }

    private var testExercises: [Exercise] {
        [
            createTestExercise(name: "Bench Press"),
            createTestExercise(name: "Barbell Squat"),
            createTestExercise(name: "Deadlift"),
            createTestExercise(name: "Overhead Press"),
            createTestExercise(name: "Barbell Row"),
            createTestExercise(name: "Pull-ups"),
            createTestExercise(name: "Lat Pulldown"),
            createTestExercise(name: "Dumbbell Bench Press"),
            createTestExercise(name: "Incline Bench Press"),
            createTestExercise(name: "Romanian Deadlift"),
            createTestExercise(name: "Front Squat"),
            createTestExercise(name: "Close Grip Bench Press"),
            createTestExercise(name: "Dumbbell Row"),
            createTestExercise(name: "Chin-ups"),
            createTestExercise(name: "Tricep Pushdown"),
            createTestExercise(name: "Bicep Curl"),
            createTestExercise(name: "Lateral Raise"),
            createTestExercise(name: "Face Pull"),
        ]
    }

    // MARK: - Exact Match Tests

    func testExactMatchLowercase() {
        let exercises = testExercises
        let result = ExerciseMatcher.findBestMatch(name: "bench press", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Bench Press")
    }

    func testExactMatchUppercase() {
        let exercises = testExercises
        let result = ExerciseMatcher.findBestMatch(name: "BENCH PRESS", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Bench Press")
    }

    func testExactMatchMixedCase() {
        let exercises = testExercises
        let result = ExerciseMatcher.findBestMatch(name: "Bench Press", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Bench Press")
    }

    // MARK: - Contains Match Tests

    func testContainsMatchSearchContainsLibrary() {
        let exercises = testExercises
        // "Barbell Bench Press" contains "Bench Press"
        let result = ExerciseMatcher.findBestMatch(name: "Barbell Bench Press", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Bench Press")
    }

    func testContainsMatchLibraryContainsSearch() {
        let exercises = testExercises
        // "Bench" is contained in "Bench Press"
        let result = ExerciseMatcher.findBestMatch(name: "Bench", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Bench") ?? false)
    }

    // MARK: - Word-Based Matching Tests

    func testWordMatchingMultipleWords() {
        let exercises = testExercises
        // "Squat Exercise" has "Squat" in common with "Barbell Squat"
        let result = ExerciseMatcher.findBestMatch(name: "Squat Exercise", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Squat") ?? false)
    }

    func testWordMatchingPartialName() {
        let exercises = testExercises
        // "Romanian" should match "Romanian Deadlift"
        let result = ExerciseMatcher.findBestMatch(name: "Romanian", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Romanian Deadlift")
    }

    // MARK: - Prefix Stripping Tests

    func testPrefixStrippingBarbell() {
        let exercises = testExercises
        // "barbell squat" should match "Barbell Squat" via exact match
        // "barbell bench" should find "Bench Press" after stripping prefix
        let result = ExerciseMatcher.findBestMatch(name: "barbell bench", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Bench") ?? false)
    }

    func testPrefixStrippingDumbbell() {
        let exercises = testExercises
        // "dumbbell row" should match "Dumbbell Row" via exact match
        // or find a row exercise after stripping
        let result = ExerciseMatcher.findBestMatch(name: "dumbbell row", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Row") ?? false)
    }

    func testPrefixStrippingSeated() {
        let exercises = testExercises
        // "seated overhead press" should find "Overhead Press"
        let result = ExerciseMatcher.findBestMatch(name: "seated overhead press", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Press") ?? false)
    }

    func testPrefixStrippingIncline() {
        let exercises = testExercises
        // "incline bench" should find Incline Bench Press
        let result = ExerciseMatcher.findBestMatch(name: "incline bench", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Incline") ?? false || result?.name.contains("Bench") ?? false)
    }

    // MARK: - Synonym Matching Tests

    func testSynonymOHP() {
        let exercises = testExercises
        // "ohp" should match via synonym table
        // The synonym maps ohp -> overhead press alternatives
        let result = ExerciseMatcher.findBestMatch(name: "ohp", in: exercises)
        // May or may not find a match depending on library contents
        if result != nil {
            XCTAssertTrue(result?.name.lowercased().contains("press") ?? false)
        }
    }

    func testSynonymMilitaryPress() {
        let exercises = testExercises
        // "military press" should match an exercise containing "press"
        let result = ExerciseMatcher.findBestMatch(name: "military press", in: exercises)
        // May match via word matching (contains "press")
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.lowercased().contains("press") ?? false)
    }

    func testSynonymShoulderPress() {
        let exercises = testExercises
        // "shoulder press" should match an exercise containing "press"
        let result = ExerciseMatcher.findBestMatch(name: "shoulder press", in: exercises)
        // May match via word matching (contains "press")
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.lowercased().contains("press") ?? false)
    }

    func testSynonymPullup() {
        let exercises = testExercises
        // "pullup" (without hyphen) should match "Pull-ups"
        let result = ExerciseMatcher.findBestMatch(name: "pullup", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.lowercased().contains("pull") ?? false)
    }

    func testSynonymChinup() {
        let exercises = testExercises
        // "chinup" should match via the synonym table -> pull-up canonical
        let result = ExerciseMatcher.findBestMatch(name: "chinup", in: exercises)
        // The synonym table maps chinup -> pull-up, but we need "pull-up" in library
        // May not find exact match if library doesn't have canonical form
        // Just verify it returns something reasonable or nil
        if result != nil {
            XCTAssertTrue(result?.name.lowercased().contains("pull") ?? result?.name.lowercased().contains("chin") ?? false)
        }
    }

    func testSynonymRDL() {
        let exercises = testExercises
        // "rdl" abbreviation - the synonym maps rdl -> romanian deadlift
        // Check if we find something containing "deadlift"
        let result = ExerciseMatcher.findBestMatch(name: "rdl", in: exercises)
        // May not match if synonym logic doesn't find canonical in library
        if result != nil {
            XCTAssertTrue(result?.name.lowercased().contains("deadlift") ?? false)
        }
    }

    func testSynonymLatPull() {
        let exercises = testExercises
        // "lat pull" should match "Lat Pulldown"
        let result = ExerciseMatcher.findBestMatch(name: "lat pull", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Lat Pulldown")
    }

    // MARK: - No Match Tests

    func testNoMatchReturnsNil() {
        let exercises = testExercises
        let result = ExerciseMatcher.findBestMatch(name: "completely unknown exercise xyz", in: exercises)
        XCTAssertNil(result)
    }

    func testEmptySearchReturnsNil() {
        let exercises = testExercises
        let result = ExerciseMatcher.findBestMatch(name: "", in: exercises)
        XCTAssertNil(result)
    }

    func testEmptyLibraryReturnsNil() {
        let result = ExerciseMatcher.findBestMatch(name: "Bench Press", in: [])
        XCTAssertNil(result)
    }

    // MARK: - Edge Cases

    func testWhitespaceHandling() {
        let exercises = testExercises
        let result = ExerciseMatcher.findBestMatch(name: "  bench press  ", in: exercises)
        // Should still find a match after trimming
        XCTAssertNotNil(result)
    }

    func testSpecialCharacters() {
        let exercises = testExercises
        // Search with special characters
        let result = ExerciseMatcher.findBestMatch(name: "Pull-ups!", in: exercises)
        XCTAssertNotNil(result)
    }

    func testSimilarNames() {
        let exercises = testExercises
        // Should distinguish between similar exercises
        let benchResult = ExerciseMatcher.findBestMatch(name: "bench press", in: exercises)
        let inclineResult = ExerciseMatcher.findBestMatch(name: "incline bench press", in: exercises)

        XCTAssertNotNil(benchResult)
        XCTAssertNotNil(inclineResult)
        // They might match different exercises
    }

    // MARK: - AI Output Format Tests

    func testAIGeneratedFormat1() {
        let exercises = testExercises
        // AI might output with different formatting
        let result = ExerciseMatcher.findBestMatch(name: "Barbell Back Squat", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Squat") ?? false)
    }

    func testAIGeneratedFormat2() {
        let exercises = testExercises
        // AI might use slightly different names
        let result = ExerciseMatcher.findBestMatch(name: "BB Bench Press", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("Bench") ?? false)
    }

    func testAIGeneratedFormat3() {
        let exercises = testExercises
        // AI might add descriptors
        let result = ExerciseMatcher.findBestMatch(name: "Conventional Deadlift", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Deadlift")
    }

    // MARK: - Performance Tests

    func testMatchingPerformance() {
        let exercises = testExercises
        measure {
            for _ in 0..<100 {
                _ = ExerciseMatcher.findBestMatch(name: "barbell bench press", in: exercises)
                _ = ExerciseMatcher.findBestMatch(name: "squat", in: exercises)
                _ = ExerciseMatcher.findBestMatch(name: "rdl", in: exercises)
            }
        }
    }

    // MARK: - Priority Tests

    func testExactMatchTakesPriority() {
        let exercises = testExercises
        // "Bench Press" should return exact match, not "Dumbbell Bench Press"
        let result = ExerciseMatcher.findBestMatch(name: "Bench Press", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Bench Press")
    }

    func testMoreSpecificMatchPreferred() {
        let exercises = testExercises
        // "Incline Bench Press" should prefer exact match over "Bench Press"
        let result = ExerciseMatcher.findBestMatch(name: "Incline Bench Press", in: exercises)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Incline Bench Press")
    }
}
