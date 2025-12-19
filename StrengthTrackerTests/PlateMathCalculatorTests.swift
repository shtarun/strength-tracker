import XCTest

/// Unit tests for PlateMathCalculator - Barbell and dumbbell loading calculations
/// Tests plate loading algorithms, warmup generation, and dumbbell matching
final class PlateMathCalculatorTests: XCTestCase {

    // MARK: - Standard Plates Configuration

    func testStandardPlatesAvailable() {
        let plates = PlateMathCalculator.standardPlates
        XCTAssertTrue(plates.contains(25))
        XCTAssertTrue(plates.contains(20))
        XCTAssertTrue(plates.contains(15))
        XCTAssertTrue(plates.contains(10))
        XCTAssertTrue(plates.contains(5))
        XCTAssertTrue(plates.contains(2.5))
        XCTAssertTrue(plates.contains(1.25))
    }

    // MARK: - Plates Per Side Tests

    func testPlatesPerSideEmptyBar() {
        // 20kg bar = empty bar
        let result = PlateMathCalculator.platesPerSide(targetWeight: 20)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, [])
    }

    func testPlatesPerSideSimpleWeight() {
        // 60kg = 20kg bar + 40kg plates = 20kg per side = one 20kg plate
        let result = PlateMathCalculator.platesPerSide(targetWeight: 60)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, [20])
    }

    func testPlatesPerSideComplexWeight() {
        // 100kg = 20kg bar + 80kg plates = 40kg per side
        // Should be 25 + 10 + 5 = 40
        let result = PlateMathCalculator.platesPerSide(targetWeight: 100)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reduce(0, +), 40, "Total plate weight per side should be 40kg")
    }

    func testPlatesPerSideWithSmallPlates() {
        // 22.5kg = 20kg bar + 2.5kg = 1.25kg per side
        let result = PlateMathCalculator.platesPerSide(targetWeight: 22.5)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, [1.25])
    }

    func testPlatesPerSideBelowBarWeight() {
        // Weight below bar weight should return nil
        let result = PlateMathCalculator.platesPerSide(targetWeight: 15)
        XCTAssertNil(result)
    }

    func testPlatesPerSideImpossibleWeight() {
        // 21kg = 20kg bar + 1kg = 0.5kg per side (not possible without micro plates)
        let result = PlateMathCalculator.platesPerSide(targetWeight: 21, availablePlates: [25, 20, 15, 10, 5, 2.5])
        XCTAssertNil(result, "Impossible weight without 1.25kg plates should return nil")
    }

    func testPlatesPerSideCustomBarWeight() {
        // 25kg bar + 50kg plates = 75kg total, 25kg per side = 25kg plate
        let result = PlateMathCalculator.platesPerSide(targetWeight: 75, barWeight: 25)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, [25])
    }

    func testPlatesPerSideLimitedPlates() {
        // Only 10kg and 5kg plates available
        // 60kg = 20kg bar + 40kg = 20kg per side = 10 + 10
        let result = PlateMathCalculator.platesPerSide(targetWeight: 60, availablePlates: [10, 5])
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reduce(0, +), 20)
    }

    // MARK: - Format Plates Tests

    func testFormatPlatesEmpty() {
        let result = PlateMathCalculator.formatPlates([])
        XCTAssertEqual(result, "Empty bar")
    }

    func testFormatPlatesSinglePlate() {
        let result = PlateMathCalculator.formatPlates([20])
        XCTAssertEqual(result, "20")
    }

    func testFormatPlatesMultiplePlates() {
        let result = PlateMathCalculator.formatPlates([25, 10, 5])
        XCTAssertEqual(result, "25 + 10 + 5")
    }

    func testFormatPlatesWithDecimal() {
        let result = PlateMathCalculator.formatPlates([20, 2.5, 1.25])
        XCTAssertTrue(result.contains("20"))
        XCTAssertTrue(result.contains("2.5"))
        XCTAssertTrue(result.contains("1.25") || result.contains("1.2"))
    }

    // MARK: - Loading Instruction Tests

    func testLoadingInstructionEmptyBar() {
        let result = PlateMathCalculator.loadingInstruction(targetWeight: 20)
        XCTAssertEqual(result, "Empty bar (20kg)")
    }

    func testLoadingInstructionWithPlates() {
        let result = PlateMathCalculator.loadingInstruction(targetWeight: 60)
        XCTAssertTrue(result.contains("each side"))
    }

    func testLoadingInstructionImpossible() {
        let result = PlateMathCalculator.loadingInstruction(targetWeight: 21, availablePlates: [25, 20, 15, 10, 5, 2.5])
        XCTAssertTrue(result.contains("Cannot load"))
    }

    // MARK: - Nearest Loadable Tests

    func testNearestLoadableExactMatch() {
        // 60kg is exactly loadable
        let result = PlateMathCalculator.nearestLoadable(weight: 60)
        XCTAssertEqual(result, 60)
    }

    func testNearestLoadableRoundUp() {
        // 62kg should round up to nearest 2.5kg increment
        // 62 - 20 = 42, 42 / 2.5 = 16.8, rounds to 17, 17 * 2.5 = 42.5, 20 + 42.5 = 62.5
        let result = PlateMathCalculator.nearestLoadable(weight: 62)
        XCTAssertEqual(result, 62.5)
    }

    func testNearestLoadableRoundDown() {
        // 59kg should round to 60kg
        let result = PlateMathCalculator.nearestLoadable(weight: 59)
        XCTAssertEqual(result, 60)
    }

    func testNearestLoadableBelowBar() {
        // Below bar weight should return bar weight
        let result = PlateMathCalculator.nearestLoadable(weight: 15)
        XCTAssertEqual(result, 20)
    }

    // MARK: - Warmup Weights Tests

    func testWarmupWeightsLightTopSet() {
        // Light top set shouldn't have many warmups
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 25)
        XCTAssertTrue(result.isEmpty || result.count <= 1)
    }

    func testWarmupWeightsModerateTopSet() {
        // 60kg top set should have warmups
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 60)
        XCTAssertGreaterThan(result.count, 0)
        // Should all be less than top set
        for warmup in result {
            XCTAssertLessThan(warmup, 60)
        }
    }

    func testWarmupWeightsHeavyTopSet() {
        // 100kg top set should include bar + multiple warmups
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 100)
        XCTAssertGreaterThan(result.count, 1)
        // Should start with empty bar
        XCTAssertEqual(result.first, 20)
        // Should be sorted
        XCTAssertEqual(result, result.sorted())
    }

    func testWarmupWeightsAreSorted() {
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 120)
        XCTAssertEqual(result, result.sorted(), "Warmups should be in ascending order")
    }

    func testWarmupWeightsNoDuplicates() {
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 100)
        let uniqueCount = Set(result).count
        XCTAssertEqual(uniqueCount, result.count, "Warmups should have no duplicates")
    }

    func testWarmupWeightsAtBarWeight() {
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 20)
        XCTAssertTrue(result.isEmpty, "Top set at bar weight should have no warmups")
    }

    // MARK: - Dumbbell Tests

    func testStandardDumbbellsAvailable() {
        let dumbbells = PlateMathCalculator.standardDumbbells
        XCTAssertGreaterThan(dumbbells.count, 0)
        XCTAssertTrue(dumbbells.contains(10))
        XCTAssertTrue(dumbbells.contains(20))
    }

    func testNearestDumbbellExactMatch() {
        let result = PlateMathCalculator.nearestDumbbell(weight: 20)
        XCTAssertEqual(result, 20)
    }

    func testNearestDumbbellRoundUp() {
        let result = PlateMathCalculator.nearestDumbbell(weight: 21)
        XCTAssertEqual(result, 20) // Closer to 20 than 22.5
    }

    func testNearestDumbbellRoundDown() {
        let result = PlateMathCalculator.nearestDumbbell(weight: 24)
        XCTAssertEqual(result, 25) // Closer to 25 than 22.5
    }

    func testNearestDumbbellCustomSet() {
        let customDumbbells: [Double] = [5, 10, 15, 20, 25, 30]
        let result = PlateMathCalculator.nearestDumbbell(weight: 17, availableDumbbells: customDumbbells)
        XCTAssertEqual(result, 15) // Closer to 15 than 20
    }

    func testNextDumbbellUp() {
        let result = PlateMathCalculator.nextDumbbellUp(from: 20)
        XCTAssertEqual(result, 22.5)
    }

    func testNextDumbbellUpAtMax() {
        let result = PlateMathCalculator.nextDumbbellUp(from: 60)
        XCTAssertNil(result, "Should return nil when at max")
    }

    func testNextDumbbellDown() {
        let result = PlateMathCalculator.nextDumbbellDown(from: 20)
        XCTAssertEqual(result, 17.5)
    }

    func testNextDumbbellDownAtMin() {
        let result = PlateMathCalculator.nextDumbbellDown(from: 2.5)
        XCTAssertNil(result, "Should return nil when at min")
    }

    func testDumbbellProgressionSequence() {
        var weight = 10.0
        var progression: [Double] = [weight]

        while let next = PlateMathCalculator.nextDumbbellUp(from: weight) {
            weight = next
            progression.append(weight)
            if weight >= 30 { break } // Limit for test
        }

        // Should have smooth 2.5kg increments
        for i in 1..<progression.count {
            let increment = progression[i] - progression[i - 1]
            XCTAssertEqual(increment, 2.5, accuracy: 0.001)
        }
    }

    // MARK: - Integration Tests

    func testCompleteLoadingWorkflow() {
        let targetWeight = 100.0

        // Calculate plates
        guard let plates = PlateMathCalculator.platesPerSide(targetWeight: targetWeight) else {
            XCTFail("Should be able to load 100kg")
            return
        }

        // Verify total weight
        let totalPlateWeight = plates.reduce(0, +) * 2 + 20 // per side × 2 + bar
        XCTAssertEqual(totalPlateWeight, targetWeight, accuracy: 0.001)

        // Format should be readable
        let formatted = PlateMathCalculator.formatPlates(plates)
        XCTAssertFalse(formatted.isEmpty)

        // Loading instruction should be complete
        let instruction = PlateMathCalculator.loadingInstruction(targetWeight: targetWeight)
        XCTAssertTrue(instruction.contains("each side"))
    }

    func testWarmupToWorksetProgression() {
        let topSetWeight = 140.0
        let warmups = PlateMathCalculator.warmupWeights(topSetWeight: topSetWeight)

        // Each warmup should be loadable
        for warmup in warmups {
            let plates = PlateMathCalculator.platesPerSide(targetWeight: warmup)
            XCTAssertNotNil(plates, "Warmup weight \(warmup) should be loadable")
        }

        // Warmups should progress reasonably
        if warmups.count >= 2 {
            for i in 1..<warmups.count {
                XCTAssertGreaterThan(warmups[i], warmups[i - 1], "Warmups should increase")
            }
        }
    }
}
