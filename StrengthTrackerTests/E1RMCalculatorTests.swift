import XCTest
@testable import StrengthTracker

final class E1RMCalculatorTests: XCTestCase {
    
    // MARK: - Epley Formula Tests
    
    func testE1RM_SingleRep_ReturnsWeight() {
        // When doing 1 rep, e1RM should equal the weight lifted
        let weight = 100.0
        let result = E1RMCalculator.calculate(weight: weight, reps: 1)
        
        XCTAssertEqual(result, weight, accuracy: 0.001)
    }
    
    func testE1RM_ZeroReps_ReturnsZero() {
        let result = E1RMCalculator.calculate(weight: 100.0, reps: 0)
        
        XCTAssertEqual(result, 0)
    }
    
    func testE1RM_FiveReps_CorrectCalculation() {
        // Epley formula: weight × (1 + reps/30)
        // 100 × (1 + 5/30) = 100 × 1.1667 = 116.67
        let result = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        
        XCTAssertEqual(result, 116.666, accuracy: 0.01)
    }
    
    func testE1RM_TenReps_CorrectCalculation() {
        // 100 × (1 + 10/30) = 100 × 1.333 = 133.33
        let result = E1RMCalculator.calculate(weight: 100.0, reps: 10)
        
        XCTAssertEqual(result, 133.333, accuracy: 0.01)
    }
    
    func testE1RM_HighReps_StillCalculates() {
        // 50 × (1 + 20/30) = 50 × 1.667 = 83.33
        let result = E1RMCalculator.calculate(weight: 50.0, reps: 20)
        
        XCTAssertEqual(result, 83.333, accuracy: 0.01)
    }
    
    // MARK: - Brzycki Formula Tests
    
    func testBrzycki_SingleRep_ReturnsWeight() {
        let result = E1RMCalculator.calculateBrzycki(weight: 100.0, reps: 1)
        
        XCTAssertEqual(result, 100.0, accuracy: 0.001)
    }
    
    func testBrzycki_FiveReps_CorrectCalculation() {
        // Brzycki: weight × (36 / (37 - reps))
        // 100 × (36 / 32) = 100 × 1.125 = 112.5
        let result = E1RMCalculator.calculateBrzycki(weight: 100.0, reps: 5)
        
        XCTAssertEqual(result, 112.5, accuracy: 0.01)
    }
    
    func testBrzycki_TenReps_CorrectCalculation() {
        // 100 × (36 / 27) = 133.33
        let result = E1RMCalculator.calculateBrzycki(weight: 100.0, reps: 10)
        
        XCTAssertEqual(result, 133.333, accuracy: 0.01)
    }
    
    func testBrzycki_InvalidReps_ReturnsWeight() {
        // Reps >= 37 would cause division issues
        let result = E1RMCalculator.calculateBrzycki(weight: 100.0, reps: 37)
        
        XCTAssertEqual(result, 100.0)
    }
    
    func testBrzycki_ZeroReps_ReturnsWeight() {
        let result = E1RMCalculator.calculateBrzycki(weight: 100.0, reps: 0)
        
        XCTAssertEqual(result, 100.0)
    }
    
    // MARK: - Weight for Reps Tests
    
    func testWeightForReps_SingleRep_ReturnsE1RM() {
        let result = E1RMCalculator.weightForReps(e1RM: 100.0, reps: 1)
        
        XCTAssertEqual(result, 100.0, accuracy: 0.001)
    }
    
    func testWeightForReps_FiveReps_CorrectWeight() {
        // Inverse: e1RM / (1 + reps/30)
        // 100 / 1.1667 = 85.71
        let result = E1RMCalculator.weightForReps(e1RM: 100.0, reps: 5)
        
        XCTAssertEqual(result, 85.714, accuracy: 0.01)
    }
    
    func testWeightForReps_TenReps_CorrectWeight() {
        // 100 / 1.333 = 75.0
        let result = E1RMCalculator.weightForReps(e1RM: 100.0, reps: 10)
        
        XCTAssertEqual(result, 75.0, accuracy: 0.01)
    }
    
    func testWeightForReps_ZeroReps_ReturnsZero() {
        let result = E1RMCalculator.weightForReps(e1RM: 100.0, reps: 0)
        
        XCTAssertEqual(result, 0)
    }
    
    func testWeightForReps_RoundTrip() {
        // If we calculate weight for 5 reps from a 100kg e1RM,
        // then calculate e1RM from that weight at 5 reps, we should get back 100
        let weight = E1RMCalculator.weightForReps(e1RM: 100.0, reps: 5)
        let e1RM = E1RMCalculator.calculate(weight: weight, reps: 5)
        
        XCTAssertEqual(e1RM, 100.0, accuracy: 0.01)
    }
    
    // MARK: - Percentage Tests
    
    func testPercentageOf1RM_MaxWeight_Returns100() {
        // 100kg for 1 rep = 100% of 1RM
        let result = E1RMCalculator.percentageOf1RM(weight: 100.0, reps: 1)
        
        XCTAssertEqual(result, 100.0, accuracy: 0.01)
    }
    
    func testPercentageOf1RM_FiveReps_ReturnsCorrect() {
        // 100kg for 5 reps: e1RM = 116.67
        // Percentage = 100/116.67 × 100 = 85.7%
        let result = E1RMCalculator.percentageOf1RM(weight: 100.0, reps: 5)
        
        XCTAssertEqual(result, 85.714, accuracy: 0.1)
    }
    
    func testPercentageOf1RM_ZeroWeight_ReturnsZero() {
        let result = E1RMCalculator.percentageOf1RM(weight: 0.0, reps: 5)
        
        XCTAssertEqual(result, 0.0)
    }
    
    // MARK: - Reps at Percentage Tests
    
    func testRepsAtPercentage_100Percent_Returns1() {
        let result = E1RMCalculator.repsAtPercentage(100.0)
        
        XCTAssertEqual(result, 1)
    }
    
    func testRepsAtPercentage_85Percent_ReturnsFive() {
        // At 85%: reps = 30 × (1/0.85 - 1) = 30 × 0.176 = 5.3 → 5
        let result = E1RMCalculator.repsAtPercentage(85.0)
        
        XCTAssertEqual(result, 5)
    }
    
    func testRepsAtPercentage_75Percent_ReturnsTen() {
        // At 75%: reps = 30 × (1/0.75 - 1) = 30 × 0.333 = 10
        let result = E1RMCalculator.repsAtPercentage(75.0)
        
        XCTAssertEqual(result, 10)
    }
    
    func testRepsAtPercentage_InvalidPercentage_Returns1() {
        let result = E1RMCalculator.repsAtPercentage(0.0)
        
        XCTAssertEqual(result, 1)
    }
    
    func testRepsAtPercentage_Over100_Returns1() {
        let result = E1RMCalculator.repsAtPercentage(110.0)
        
        XCTAssertEqual(result, 1)
    }
    
    // MARK: - Real-World Scenarios
    
    func testE1RM_BenchPressScenario() {
        // User benches 100kg for 5 reps at RPE 8
        // Expected e1RM ≈ 117kg
        let e1RM = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        
        XCTAssertTrue(e1RM > 115 && e1RM < 120, "e1RM should be around 117kg")
    }
    
    func testE1RM_SquatScenario() {
        // User squats 140kg for 3 reps
        // Expected e1RM = 140 × (1 + 3/30) = 154kg
        let e1RM = E1RMCalculator.calculate(weight: 140.0, reps: 3)
        
        XCTAssertEqual(e1RM, 154.0, accuracy: 0.1)
    }
    
    func testWeightForReps_WorkingSetCalculation() {
        // Given 150kg e1RM, calculate weight for 8 rep set
        // 150 / (1 + 8/30) = 150 / 1.267 = 118.4kg
        let weight = E1RMCalculator.weightForReps(e1RM: 150.0, reps: 8)
        
        XCTAssertEqual(weight, 118.42, accuracy: 0.1)
    }
}
