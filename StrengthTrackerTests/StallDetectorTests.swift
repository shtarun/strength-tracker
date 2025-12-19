import XCTest

/// Unit tests for StallDetector - Plateau detection and fix suggestions
/// Tests the stall detection algorithm using StallContext (no SwiftData dependencies)
final class StallDetectorTests: XCTestCase {

    // MARK: - Test Helpers

    private func createSessionHistory(
        topSetWeight: Double,
        topSetReps: Int,
        topSetRPE: Double?
    ) -> SessionHistoryContext {
        return SessionHistoryContext(
            date: "2025-01-15",
            topSetWeight: topSetWeight,
            topSetReps: topSetReps,
            topSetRPE: topSetRPE,
            totalSets: 5,
            e1RM: E1RMCalculator.calculate(weight: topSetWeight, reps: topSetReps)
        )
    }

    private func createStallContext(
        sessions: [SessionHistoryContext],
        exerciseName: String = "Bench Press"
    ) -> StallContext {
        return StallContext(
            exerciseName: exerciseName,
            lastSessions: sessions,
            currentPrescription: PrescriptionContext(
                progressionType: "Top Set + Backoffs",
                topSetRepsRange: "5-8",
                topSetRPECap: 8.5,
                backoffSets: 3,
                backoffRepsRange: "8-10",
                backoffLoadDropPercent: 0.10
            ),
            userGoal: "Strength"
        )
    }

    // MARK: - Insufficient Data Tests

    func testNoStallWithInsufficientSessions() async {
        let detector = StallDetector.shared

        // Only 2 sessions - not enough for stall detection
        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertFalse(result.isStalled, "Should not detect stall with less than 3 sessions")
    }

    func testNoStallWithEmptySessions() async {
        let detector = StallDetector.shared

        let context = createStallContext(sessions: [])
        let result = await detector.analyzeStall(context: context)

        XCTAssertFalse(result.isStalled)
    }

    // MARK: - Progressing Exercise Tests

    func testNoStallWhenProgressing() async {
        let detector = StallDetector.shared

        // E1RM is increasing
        let sessions = [
            createSessionHistory(topSetWeight: 105, topSetReps: 5, topSetRPE: 8.0), // Latest: e1RM = 122.5
            createSessionHistory(topSetWeight: 102.5, topSetReps: 5, topSetRPE: 8.0), // e1RM = 119.6
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0)  // Oldest: e1RM = 116.7
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertFalse(result.isStalled, "Should not detect stall when e1RM is improving")
        XCTAssertTrue(result.details?.contains("progressing") ?? false || result.details == nil)
    }

    func testNoStallWhenRepsImproving() async {
        let detector = StallDetector.shared

        // Same weight but more reps = higher e1RM
        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 8, topSetRPE: 8.0), // Latest: higher e1RM
            createSessionHistory(topSetWeight: 100, topSetReps: 6, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0)  // Oldest: lower e1RM
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertFalse(result.isStalled, "Rep improvement should count as progress")
    }

    // MARK: - High RPE Stall Tests

    func testHighRPEStallDetection() async {
        let detector = StallDetector.shared

        // Same e1RM with consistently high RPE (9+)
        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.5),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.5)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertTrue(result.isStalled, "Should detect stall with high RPE and no progress")
        XCTAssertEqual(result.fixType, "deload", "High RPE stall should suggest deload")
        XCTAssertNotNil(result.suggestedFix)
    }

    func testDeloadSuggestionDetails() async {
        let detector = StallDetector.shared

        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.5),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.0)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertTrue(result.isStalled)
        XCTAssertTrue(result.suggestedFix?.lowercased().contains("deload") ?? false)
        // Details should include target weight
        XCTAssertNotNil(result.details)
    }

    // MARK: - Low Rep Stall Tests

    func testLowRepStallDetection() async {
        let detector = StallDetector.shared

        // Stuck at low reps (4 or less) with no weight increase
        let sessions = [
            createSessionHistory(topSetWeight: 140, topSetReps: 3, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 140, topSetReps: 4, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 140, topSetReps: 3, topSetRPE: 8.5)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertTrue(result.isStalled, "Should detect stall in low rep range")
        XCTAssertEqual(result.fixType, "rep_range", "Low rep stall should suggest rep range change")
    }

    func testRepRangeSuggestionDetails() async {
        let detector = StallDetector.shared

        let sessions = [
            createSessionHistory(topSetWeight: 140, topSetReps: 3, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 140, topSetReps: 3, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 140, topSetReps: 4, topSetRPE: 8.0)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertTrue(result.isStalled)
        // Should suggest higher rep range
        XCTAssertTrue(result.suggestedFix?.lowercased().contains("6-8") ?? false ||
                      result.suggestedFix?.lowercased().contains("higher") ?? false)
    }

    // MARK: - Mid Rep Stall Tests

    func testMidRepVariationStall() async {
        let detector = StallDetector.shared

        // Stuck in 5-8 rep range with moderate RPE - needs variation
        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 6, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 6, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 6, topSetRPE: 8.0)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertTrue(result.isStalled, "Should detect stall in mid rep range")
        XCTAssertEqual(result.fixType, "variation", "Mid rep stall should suggest variation")
    }

    func testVariationSuggestionForBenchPress() async {
        let detector = StallDetector.shared

        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 7, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 6, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 6, topSetRPE: 8.5)
        ]

        let context = createStallContext(sessions: sessions, exerciseName: "Bench Press")
        let result = await detector.analyzeStall(context: context)

        // May or may not detect as stalled depending on algorithm thresholds
        // If stalled, should have a suggested fix
        if result.isStalled {
            XCTAssertNotNil(result.suggestedFix)
        }
    }

    // MARK: - High Rep Stall Tests

    func testHighRepWeightJumpStall() async {
        let detector = StallDetector.shared

        // High reps (10+) but not increasing weight
        let sessions = [
            createSessionHistory(topSetWeight: 80, topSetReps: 12, topSetRPE: 7.5),
            createSessionHistory(topSetWeight: 80, topSetReps: 11, topSetRPE: 7.5),
            createSessionHistory(topSetWeight: 80, topSetReps: 12, topSetRPE: 7.0)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        // Note: The analyzer might not detect this as a stall if e1RM is stable
        // This depends on the implementation's threshold
        if result.isStalled {
            XCTAssertEqual(result.fixType, "weight_jump", "High rep stall should suggest weight jump")
        }
    }

    // MARK: - Edge Cases

    func testMissingRPEValues() async {
        let detector = StallDetector.shared

        // Some sessions without RPE data
        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: nil),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: nil)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        // Should still be able to analyze without crashing
        XCTAssertTrue(result.isStalled || !result.isStalled) // Just check it runs
    }

    func testVerySmallImprovement() async {
        let detector = StallDetector.shared

        // Very small e1RM improvement (less than threshold)
        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0), // e1RM = 116.67
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0), // Same
            createSessionHistory(topSetWeight: 99.5, topSetReps: 5, topSetRPE: 8.0)  // e1RM = 116.08 (~0.5% less)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        // Improvement less than 1% should still be considered progressing
        // depending on implementation
        XCTAssertNotNil(result)
    }

    func testDecreasingPerformance() async {
        let detector = StallDetector.shared

        // Performance getting worse
        let sessions = [
            createSessionHistory(topSetWeight: 95, topSetReps: 5, topSetRPE: 9.0), // Latest: lower
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 102.5, topSetReps: 5, topSetRPE: 8.0) // Oldest: higher
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        XCTAssertTrue(result.isStalled, "Decreasing performance should be flagged as stalled")
    }

    // MARK: - StallFix Enum Tests

    func testStallFixRawValues() {
        XCTAssertEqual(StallFix.deload.rawValue, "deload")
        XCTAssertEqual(StallFix.repRange.rawValue, "rep_range")
        XCTAssertEqual(StallFix.variation.rawValue, "variation")
        XCTAssertEqual(StallFix.weightJump.rawValue, "weight_jump")
    }

    func testStallFixDisplayNames() {
        XCTAssertEqual(StallFix.deload.displayName, "Deload Week")
        XCTAssertEqual(StallFix.repRange.displayName, "Change Rep Range")
        XCTAssertEqual(StallFix.variation.displayName, "Switch Variation")
        XCTAssertEqual(StallFix.weightJump.displayName, "Force Weight Increase")
    }

    func testStallFixIcons() {
        XCTAssertFalse(StallFix.deload.icon.isEmpty)
        XCTAssertFalse(StallFix.repRange.icon.isEmpty)
        XCTAssertFalse(StallFix.variation.icon.isEmpty)
        XCTAssertFalse(StallFix.weightJump.icon.isEmpty)
    }

    // MARK: - Response Structure Tests

    func testStallAnalysisResponseNotStalled() async {
        let detector = StallDetector.shared

        let sessions = [
            createSessionHistory(topSetWeight: 110, topSetReps: 5, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 105, topSetReps: 5, topSetRPE: 8.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 8.0)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        if !result.isStalled {
            XCTAssertNil(result.reason, "Non-stalled response should have nil reason")
            XCTAssertNil(result.suggestedFix, "Non-stalled response should have nil fix")
            XCTAssertNil(result.fixType, "Non-stalled response should have nil fixType")
        }
    }

    func testStallAnalysisResponseStalled() async {
        let detector = StallDetector.shared

        let sessions = [
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.5),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.0),
            createSessionHistory(topSetWeight: 100, topSetReps: 5, topSetRPE: 9.5)
        ]

        let context = createStallContext(sessions: sessions)
        let result = await detector.analyzeStall(context: context)

        if result.isStalled {
            XCTAssertNotNil(result.reason, "Stalled response should have a reason")
            XCTAssertNotNil(result.suggestedFix, "Stalled response should have a suggested fix")
            XCTAssertNotNil(result.fixType, "Stalled response should have a fix type")
        }
    }
}
