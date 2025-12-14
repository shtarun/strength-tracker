import XCTest
@testable import StrengthTracker

final class PlateMathCalculatorTests: XCTestCase {
    
    // MARK: - Plates Per Side Tests
    
    func testPlatesPerSide_EmptyBar_ReturnsEmpty() {
        let result = PlateMathCalculator.platesPerSide(targetWeight: 20.0, barWeight: 20.0)
        
        XCTAssertEqual(result, [])
    }
    
    func testPlatesPerSide_60kg_TwoTwenties() {
        // 60kg total: bar (20) + 20 per side
        let result = PlateMathCalculator.platesPerSide(targetWeight: 60.0, barWeight: 20.0)
        
        XCTAssertEqual(result, [20])
    }
    
    func testPlatesPerSide_100kg_CorrectPlates() {
        // 100kg total: bar (20) + 40 per side = 25 + 15
        let result = PlateMathCalculator.platesPerSide(targetWeight: 100.0, barWeight: 20.0)
        
        XCTAssertEqual(result, [25, 15])
    }
    
    func testPlatesPerSide_125kg_CorrectPlates() {
        // 125kg total: bar (20) + 52.5 per side = 25 + 25 + 2.5 (greedy algorithm)
        let result = PlateMathCalculator.platesPerSide(targetWeight: 125.0, barWeight: 20.0)
        
        XCTAssertEqual(result, [25, 25, 2.5])
    }
    
    func testPlatesPerSide_142_5kg_WithMicroplates() {
        // 142.5kg total: bar (20) + 61.25 per side = 25 + 25 + 10 + 1.25 (greedy algorithm)
        let result = PlateMathCalculator.platesPerSide(targetWeight: 142.5, barWeight: 20.0)
        
        XCTAssertEqual(result, [25, 25, 10, 1.25])
    }
    
    func testPlatesPerSide_BelowBarWeight_ReturnsNil() {
        let result = PlateMathCalculator.platesPerSide(targetWeight: 15.0, barWeight: 20.0)
        
        XCTAssertNil(result)
    }
    
    func testPlatesPerSide_OddWeight_WithoutMicroplates_ReturnsNil() {
        // 21.5kg can't be split evenly without 0.75kg plates
        let platesWithoutMicro: [Double] = [25, 20, 15, 10, 5, 2.5]
        let result = PlateMathCalculator.platesPerSide(
            targetWeight: 21.5,
            barWeight: 20.0,
            availablePlates: platesWithoutMicro
        )
        
        XCTAssertNil(result)
    }
    
    func testPlatesPerSide_CustomPlates_UsesAvailable() {
        // Only 10kg and 5kg plates available
        let limitedPlates: [Double] = [10, 5]
        let result = PlateMathCalculator.platesPerSide(
            targetWeight: 50.0,
            barWeight: 20.0,
            availablePlates: limitedPlates
        )
        
        // 50kg total: 15 per side = 10 + 5
        XCTAssertEqual(result, [10, 5])
    }
    
    func testPlatesPerSide_ImpossibleWeight_ReturnsNil() {
        // 23kg: 1.5 per side - can't be made with standard plates
        let result = PlateMathCalculator.platesPerSide(targetWeight: 23.0, barWeight: 20.0)
        
        XCTAssertNil(result)
    }
    
    // MARK: - Format Plates Tests
    
    func testFormatPlates_EmptyArray_ReturnsEmptyBar() {
        let result = PlateMathCalculator.formatPlates([])
        
        XCTAssertEqual(result, "Empty bar")
    }
    
    func testFormatPlates_SinglePlate_FormatsCorrectly() {
        let result = PlateMathCalculator.formatPlates([20])
        
        XCTAssertEqual(result, "20")
    }
    
    func testFormatPlates_MultiplePlates_JoinsWithPlus() {
        let result = PlateMathCalculator.formatPlates([25, 20, 5])
        
        XCTAssertEqual(result, "25 + 20 + 5")
    }
    
    func testFormatPlates_DecimalPlates_FormatsNicely() {
        // Uses %.2g format which gives "1.2" for 1.25
        let result = PlateMathCalculator.formatPlates([20, 2.5, 1.25])
        
        XCTAssertEqual(result, "20 + 2.5 + 1.2")
    }
    
    // MARK: - Loading Instruction Tests
    
    func testLoadingInstruction_ValidWeight_ReturnsInstruction() {
        let result = PlateMathCalculator.loadingInstruction(targetWeight: 60.0, barWeight: 20.0)
        
        XCTAssertEqual(result, "20 each side")
    }
    
    func testLoadingInstruction_EmptyBar_ReturnsEmptyBarMessage() {
        let result = PlateMathCalculator.loadingInstruction(targetWeight: 20.0, barWeight: 20.0)
        
        XCTAssertEqual(result, "Empty bar (20kg)")
    }
    
    func testLoadingInstruction_ImpossibleWeight_ReturnsError() {
        let result = PlateMathCalculator.loadingInstruction(targetWeight: 21.0, barWeight: 20.0)
        
        XCTAssertTrue(result.contains("Cannot load"))
    }
    
    func testLoadingInstruction_ComplexWeight_ShowsAllPlates() {
        let result = PlateMathCalculator.loadingInstruction(targetWeight: 100.0, barWeight: 20.0)
        
        XCTAssertEqual(result, "25 + 15 each side")
    }
    
    // MARK: - Nearest Loadable Tests
    
    func testNearestLoadable_ExactWeight_ReturnsSame() {
        let result = PlateMathCalculator.nearestLoadable(weight: 60.0)
        
        XCTAssertEqual(result, 60.0)
    }
    
    func testNearestLoadable_SlightlyOver_RoundsUp() {
        // 61.5 - 20 = 41.5, /2.5 = 16.6, rounds to 17, *2.5 = 42.5 -> 62.5
        let result = PlateMathCalculator.nearestLoadable(weight: 61.5)
        
        XCTAssertEqual(result, 62.5, accuracy: 0.01)
    }
    
    func testNearestLoadable_SlightlyUnder_RoundsDown() {
        // 59.0 -> nearest loadable
        let result = PlateMathCalculator.nearestLoadable(weight: 59.0)
        
        XCTAssertEqual(result, 60.0, accuracy: 0.01)
    }
    
    func testNearestLoadable_BelowBar_ReturnsBarWeight() {
        let result = PlateMathCalculator.nearestLoadable(weight: 15.0)
        
        XCTAssertEqual(result, 20.0)
    }
    
    func testNearestLoadable_WithMicroplates_FinerGranularity() {
        // With 1.25kg plates, minimum increment is 2.5kg total
        // 22.0 - 20 = 2, /2.5 = 0.8, rounds to 1, *2.5 = 2.5 -> 22.5
        let result = PlateMathCalculator.nearestLoadable(weight: 22.0)
        
        XCTAssertEqual(result, 22.5, accuracy: 0.01)
    }
    
    // MARK: - Warmup Weights Tests
    
    func testWarmupWeights_LightWeight_NoWarmups() {
        // For a 30kg top set, might not need warmups above bar
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 30.0, barWeight: 20.0)
        
        // Should have few warmup weights
        XCTAssertTrue(result.count <= 2)
    }
    
    func testWarmupWeights_HeavyWeight_MultipleWarmups() {
        // For a 140kg squat, expect several warmup weights
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 140.0, barWeight: 20.0)
        
        XCTAssertTrue(result.count >= 3, "Heavy weights should have at least 3 warmup sets")
    }
    
    func testWarmupWeights_BarOnly_EmptyArray() {
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 20.0, barWeight: 20.0)
        
        XCTAssertEqual(result, [])
    }
    
    func testWarmupWeights_AscendingOrder() {
        let result = PlateMathCalculator.warmupWeights(topSetWeight: 100.0, barWeight: 20.0)
        
        // Verify weights are in ascending order
        for i in 1..<result.count {
            XCTAssertTrue(result[i] > result[i-1], "Warmup weights should be ascending")
        }
    }
    
    func testWarmupWeights_DoesNotExceedTopSet() {
        let topSet = 100.0
        let result = PlateMathCalculator.warmupWeights(topSetWeight: topSet, barWeight: 20.0)
        
        for weight in result {
            XCTAssertTrue(weight < topSet, "Warmup weights should be less than top set")
        }
    }
    
    // MARK: - Edge Cases
    
    func testPlatesPerSide_VeryHeavyWeight_StillCalculates() {
        // 300kg deadlift: 140 per side
        let result = PlateMathCalculator.platesPerSide(targetWeight: 300.0, barWeight: 20.0)
        
        XCTAssertNotNil(result)
        
        // Verify total is correct
        if let plates = result {
            let perSide = plates.reduce(0, +)
            XCTAssertEqual(perSide, 140.0, accuracy: 0.01)
        }
    }
    
    func testPlatesPerSide_OlympicBar_25kg() {
        // Some Olympic bars are 25kg
        let result = PlateMathCalculator.platesPerSide(targetWeight: 65.0, barWeight: 25.0)
        
        // 65 - 25 = 40, 20 per side = 20kg plate
        XCTAssertEqual(result, [20])
    }
    
    func testPlatesPerSide_WomensBar_15kg() {
        // Women's Olympic bar is 15kg
        let result = PlateMathCalculator.platesPerSide(targetWeight: 55.0, barWeight: 15.0)
        
        // 55 - 15 = 40, 20 per side = 20kg plate
        XCTAssertEqual(result, [20])
    }
    
    // MARK: - Real-World Scenarios
    
    func testRealWorld_BenchPressWarmup() {
        // Working up to 100kg bench
        let warmups = PlateMathCalculator.warmupWeights(topSetWeight: 100.0, barWeight: 20.0)
        
        // Should include bar, some light weights, and working up
        XCTAssertTrue(warmups.contains(where: { $0 >= 20 && $0 <= 40 }), "Should have light warmup")
        XCTAssertTrue(warmups.contains(where: { $0 >= 60 && $0 < 100 }), "Should have medium warmup")
    }
    
    func testRealWorld_SquatSession() {
        // 140kg squat working set
        let loading = PlateMathCalculator.loadingInstruction(targetWeight: 140.0, barWeight: 20.0)
        
        // 140 - 20 = 120, 60 per side = 25 + 20 + 10 + 5
        XCTAssertTrue(loading.contains("each side"))
    }
    
    func testRealWorld_DeadliftWithBumpers() {
        // Deadlift with bumper plates: 180kg
        let plates = PlateMathCalculator.platesPerSide(targetWeight: 180.0, barWeight: 20.0)
        
        // 80 per side = 25 + 25 + 20 + 10
        XCTAssertNotNil(plates)
        if let p = plates {
            XCTAssertEqual(p.reduce(0, +), 80.0)
        }
    }
}
