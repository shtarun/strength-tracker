import XCTest
@testable import StrengthTracker

final class StallDetectorTests: XCTestCase {
    
    // MARK: - StallFix Enum Tests
    
    func testStallFix_AllCases() {
        let allCases = StallFix.allCases
        
        XCTAssertTrue(allCases.contains(.deload))
        XCTAssertTrue(allCases.contains(.repRange))
        XCTAssertTrue(allCases.contains(.variation))
        XCTAssertTrue(allCases.contains(.weightJump))
    }
    
    func testStallFix_RawValues() {
        XCTAssertEqual(StallFix.deload.rawValue, "deload")
        XCTAssertEqual(StallFix.repRange.rawValue, "rep_range")
        XCTAssertEqual(StallFix.variation.rawValue, "variation")
        XCTAssertEqual(StallFix.weightJump.rawValue, "weight_jump")
    }
    
    func testStallFix_DisplayNames() {
        XCTAssertEqual(StallFix.deload.displayName, "Deload Week")
        XCTAssertEqual(StallFix.repRange.displayName, "Change Rep Range")
        XCTAssertEqual(StallFix.variation.displayName, "Switch Variation")
        XCTAssertEqual(StallFix.weightJump.displayName, "Force Weight Increase")
    }
    
    func testStallFix_Icons() {
        XCTAssertEqual(StallFix.deload.icon, "arrow.down.circle")
        XCTAssertEqual(StallFix.repRange.icon, "number.circle")
        XCTAssertEqual(StallFix.variation.icon, "arrow.triangle.swap")
        XCTAssertEqual(StallFix.weightJump.icon, "arrow.up.circle")
    }
}

// MARK: - StallAnalysisResponse Tests

final class StallAnalysisResponseTests: XCTestCase {
    
    func testStallAnalysisResponse_NotStalled() {
        let response = StallAnalysisResponse(
            isStalled: false,
            reason: nil,
            suggestedFix: nil,
            fixType: nil,
            details: "Exercise progressing well"
        )
        
        XCTAssertFalse(response.isStalled)
        XCTAssertNil(response.reason)
        XCTAssertNil(response.suggestedFix)
        XCTAssertNil(response.fixType)
        XCTAssertEqual(response.details, "Exercise progressing well")
    }
    
    func testStallAnalysisResponse_Stalled() {
        let response = StallAnalysisResponse(
            isStalled: true,
            reason: "No progress for 4 sessions",
            suggestedFix: "Try a deload week",
            fixType: StallFix.deload.rawValue,
            details: "Reduce weight by 10%"
        )
        
        XCTAssertTrue(response.isStalled)
        XCTAssertEqual(response.reason, "No progress for 4 sessions")
        XCTAssertEqual(response.suggestedFix, "Try a deload week")
        XCTAssertEqual(response.fixType, "deload")
        XCTAssertEqual(response.details, "Reduce weight by 10%")
    }
}

// MARK: - SessionHistoryContext Tests

final class SessionHistoryContextTests: XCTestCase {
    
    func testSessionHistoryContext_Creation() {
        let context = SessionHistoryContext(
            date: "2024-01-15",
            topSetWeight: 100.0,
            topSetReps: 5,
            topSetRPE: 8.0,
            totalSets: 4,
            e1RM: 116.0
        )
        
        XCTAssertEqual(context.date, "2024-01-15")
        XCTAssertEqual(context.topSetWeight, 100.0)
        XCTAssertEqual(context.topSetReps, 5)
        XCTAssertEqual(context.topSetRPE, 8.0)
        XCTAssertEqual(context.totalSets, 4)
        XCTAssertEqual(context.e1RM, 116.0)
    }
    
    func testSessionHistoryContext_OptionalRPE() {
        let context = SessionHistoryContext(
            date: "2024-01-15",
            topSetWeight: 100.0,
            topSetReps: 5,
            topSetRPE: nil,
            totalSets: 4,
            e1RM: 116.0
        )
        
        XCTAssertNil(context.topSetRPE)
    }
}

// MARK: - E1RM Integration Tests for Stall Detection

final class StallE1RMCalculationTests: XCTestCase {
    
    func testE1RMCalculation_UsedForStallDetection() {
        // Verify e1RM calculation that would be used in stall detection
        let weight = 100.0
        let reps = 5
        let e1RM = E1RMCalculator.calculate(weight: weight, reps: reps)
        
        // e1RM should be higher than the actual weight lifted
        XCTAssertGreaterThan(e1RM, weight)
        
        // e1RM with more reps at same weight should be higher
        let higherRepsE1RM = E1RMCalculator.calculate(weight: weight, reps: 8)
        XCTAssertGreaterThan(higherRepsE1RM, e1RM)
    }
    
    func testProgressionDetection_IncreasingE1RM() {
        // Session 1: 100kg x 5 reps
        let e1RM1 = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        
        // Session 2: 102.5kg x 5 reps (progressed)
        let e1RM2 = E1RMCalculator.calculate(weight: 102.5, reps: 5)
        
        // Session 3: 105kg x 5 reps (progressed)
        let e1RM3 = E1RMCalculator.calculate(weight: 105.0, reps: 5)
        
        // Verify progression is detectable
        XCTAssertGreaterThan(e1RM2, e1RM1)
        XCTAssertGreaterThan(e1RM3, e1RM2)
    }
    
    func testStallDetection_FlatE1RM() {
        // All sessions have same e1RM - indicates stall
        let e1RM1 = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        let e1RM2 = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        let e1RM3 = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        
        // All should be equal (indicating stall)
        XCTAssertEqual(e1RM1, e1RM2)
        XCTAssertEqual(e1RM2, e1RM3)
    }
    
    func testStallDetection_DecreasingE1RM() {
        // e1RM decreasing indicates regression
        let e1RM1 = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        let e1RM2 = E1RMCalculator.calculate(weight: 100.0, reps: 4)
        let e1RM3 = E1RMCalculator.calculate(weight: 100.0, reps: 3)
        
        // Verify regression is detectable
        XCTAssertGreaterThan(e1RM1, e1RM2)
        XCTAssertGreaterThan(e1RM2, e1RM3)
    }
}
