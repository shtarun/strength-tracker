import XCTest

/// Unit tests for E1RMCalculator - Estimated One Rep Max calculations
/// Tests the Epley and Brzycki formulas for strength estimation
final class E1RMCalculatorTests: XCTestCase {

    // MARK: - Epley Formula Tests (Default)

    func testCalculateWithSingleRep() {
        // Single rep should return the weight itself
        let result = E1RMCalculator.calculate(weight: 100, reps: 1)
        XCTAssertEqual(result, 100, accuracy: 0.001, "Single rep e1RM should equal the weight")
    }

    func testCalculateWithZeroReps() {
        // Zero reps should return 0
        let result = E1RMCalculator.calculate(weight: 100, reps: 0)
        XCTAssertEqual(result, 0, "Zero reps should return 0")
    }

    func testCalculateWithNegativeReps() {
        // Negative reps should return 0
        let result = E1RMCalculator.calculate(weight: 100, reps: -5)
        XCTAssertEqual(result, 0, "Negative reps should return 0")
    }

    func testCalculateWithStandardReps() {
        // Epley formula: e1RM = weight × (1 + reps/30)
        // 100kg × 5 reps: 100 × (1 + 5/30) = 100 × 1.1667 = 116.67
        let result = E1RMCalculator.calculate(weight: 100, reps: 5)
        let expected = 100.0 * (1.0 + 5.0 / 30.0)
        XCTAssertEqual(result, expected, accuracy: 0.001, "Epley formula should calculate correctly")
    }

    func testCalculateWith10Reps() {
        // 100kg × 10 reps: 100 × (1 + 10/30) = 100 × 1.333 = 133.33
        let result = E1RMCalculator.calculate(weight: 100, reps: 10)
        let expected = 100.0 * (1.0 + 10.0 / 30.0)
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    func testCalculateWithHighReps() {
        // Formula should still work with high reps
        let result = E1RMCalculator.calculate(weight: 50, reps: 20)
        let expected = 50.0 * (1.0 + 20.0 / 30.0)
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    func testCalculateWithZeroWeight() {
        let result = E1RMCalculator.calculate(weight: 0, reps: 10)
        XCTAssertEqual(result, 0, accuracy: 0.001, "Zero weight should return 0")
    }

    // MARK: - Brzycki Formula Tests

    func testBrzyckiWithSingleRep() {
        let result = E1RMCalculator.calculateBrzycki(weight: 100, reps: 1)
        XCTAssertEqual(result, 100, accuracy: 0.001, "Single rep should equal weight")
    }

    func testBrzyckiWithZeroReps() {
        let result = E1RMCalculator.calculateBrzycki(weight: 100, reps: 0)
        XCTAssertEqual(result, 100, "Zero reps should return weight")
    }

    func testBrzyckiWithNegativeReps() {
        let result = E1RMCalculator.calculateBrzycki(weight: 100, reps: -1)
        XCTAssertEqual(result, 100, "Negative reps should return weight")
    }

    func testBrzyckiWithStandardReps() {
        // Brzycki formula: e1RM = weight × (36 / (37 - reps))
        // 100kg × 5 reps: 100 × (36 / 32) = 100 × 1.125 = 112.5
        let result = E1RMCalculator.calculateBrzycki(weight: 100, reps: 5)
        let expected = 100.0 * (36.0 / (37.0 - 5.0))
        XCTAssertEqual(result, expected, accuracy: 0.001, "Brzycki formula should calculate correctly")
    }

    func testBrzyckiWith10Reps() {
        // 100kg × 10 reps: 100 × (36 / 27) = 100 × 1.333 = 133.33
        let result = E1RMCalculator.calculateBrzycki(weight: 100, reps: 10)
        let expected = 100.0 * (36.0 / 27.0)
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    func testBrzyckiWithEdgeReps() {
        // 36 reps: 100 × (36 / 1) = 3600
        let result = E1RMCalculator.calculateBrzycki(weight: 100, reps: 36)
        let expected = 100.0 * (36.0 / 1.0)
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    func testBrzyckiWith37OrMoreReps() {
        // 37+ reps causes division by zero or negative, should return weight
        let result37 = E1RMCalculator.calculateBrzycki(weight: 100, reps: 37)
        XCTAssertEqual(result37, 100, "37 reps should return weight (edge case)")

        let result50 = E1RMCalculator.calculateBrzycki(weight: 100, reps: 50)
        XCTAssertEqual(result50, 100, "50 reps should return weight (edge case)")
    }

    // MARK: - Weight For Reps Tests

    func testWeightForRepsWithSingleRep() {
        // 1 rep should return the full e1RM
        let result = E1RMCalculator.weightForReps(e1RM: 100, reps: 1)
        XCTAssertEqual(result, 100, accuracy: 0.001)
    }

    func testWeightForRepsWithZeroReps() {
        let result = E1RMCalculator.weightForReps(e1RM: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    func testWeightForRepsWithStandardReps() {
        // Inverse of Epley: weight = e1RM / (1 + reps/30)
        // For 5 reps at 100kg e1RM: 100 / 1.1667 = 85.71
        let result = E1RMCalculator.weightForReps(e1RM: 100, reps: 5)
        let expected = 100.0 / (1.0 + 5.0 / 30.0)
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    func testWeightForRepsRoundTrip() {
        // Calculate e1RM then back to weight should give original weight
        let originalWeight = 80.0
        let reps = 8
        let e1RM = E1RMCalculator.calculate(weight: originalWeight, reps: reps)
        let calculatedWeight = E1RMCalculator.weightForReps(e1RM: e1RM, reps: reps)
        XCTAssertEqual(calculatedWeight, originalWeight, accuracy: 0.001, "Round trip should preserve original weight")
    }

    // MARK: - Percentage of 1RM Tests

    func testPercentageOf1RMWithSingleRep() {
        // Single rep at any weight is 100% of e1RM
        let result = E1RMCalculator.percentageOf1RM(weight: 100, reps: 1)
        XCTAssertEqual(result, 100, accuracy: 0.001)
    }

    func testPercentageOf1RMWithMultipleReps() {
        // 100kg × 5 reps: e1RM = 116.67, percentage = 100/116.67 = 85.7%
        let result = E1RMCalculator.percentageOf1RM(weight: 100, reps: 5)
        let e1RM = E1RMCalculator.calculate(weight: 100, reps: 5)
        let expected = 100.0 / e1RM * 100.0
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    func testPercentageOf1RMWithZeroReps() {
        let result = E1RMCalculator.percentageOf1RM(weight: 100, reps: 0)
        XCTAssertEqual(result, 0)
    }

    func testPercentageOf1RMWithZeroWeight() {
        let result = E1RMCalculator.percentageOf1RM(weight: 0, reps: 5)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Reps at Percentage Tests

    func testRepsAtPercentage100() {
        // 100% = 1 rep
        let result = E1RMCalculator.repsAtPercentage(100)
        XCTAssertEqual(result, 1)
    }

    func testRepsAtPercentage90() {
        // ~90% is approximately 3-4 reps
        let result = E1RMCalculator.repsAtPercentage(90)
        XCTAssertGreaterThanOrEqual(result, 3)
        XCTAssertLessThanOrEqual(result, 4)
    }

    func testRepsAtPercentage75() {
        // ~75% is approximately 10 reps
        let result = E1RMCalculator.repsAtPercentage(75)
        XCTAssertGreaterThanOrEqual(result, 8)
        XCTAssertLessThanOrEqual(result, 12)
    }

    func testRepsAtPercentageEdgeCases() {
        // 0% or negative should return 1
        XCTAssertEqual(E1RMCalculator.repsAtPercentage(0), 1)
        XCTAssertEqual(E1RMCalculator.repsAtPercentage(-10), 1)

        // Greater than 100% should return 1
        XCTAssertEqual(E1RMCalculator.repsAtPercentage(110), 1)
    }

    // MARK: - Integration Tests

    func testEpleyVsBrzyckiComparison() {
        // Both formulas should give similar results in the 5-10 rep range
        for reps in 5...10 {
            let epley = E1RMCalculator.calculate(weight: 100, reps: reps)
            let brzycki = E1RMCalculator.calculateBrzycki(weight: 100, reps: reps)
            let difference = abs(epley - brzycki)
            // Formulas should be within 5% of each other
            XCTAssertLessThan(difference, epley * 0.05, "Epley and Brzycki should be similar at \(reps) reps")
        }
    }

    func testRealWorldBenchPress() {
        // Test with realistic bench press numbers
        // 100kg for 5 reps should estimate around 116-118kg 1RM
        let e1RM = E1RMCalculator.calculate(weight: 100, reps: 5)
        XCTAssertGreaterThan(e1RM, 110)
        XCTAssertLessThan(e1RM, 125)
    }

    func testRealWorldSquat() {
        // 140kg for 3 reps
        let e1RM = E1RMCalculator.calculate(weight: 140, reps: 3)
        XCTAssertGreaterThan(e1RM, 145)
        XCTAssertLessThan(e1RM, 160)
    }
}
