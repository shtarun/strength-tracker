import XCTest
@testable import StrengthTracker

// MARK: - Exercise Model Tests

final class ExerciseModelTests: XCTestCase {
    
    func testExercise_Creation() {
        let exercise = Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .frontDelt],
            equipmentRequired: [.barbell, .bench]
        )
        
        XCTAssertEqual(exercise.name, "Bench Press")
        XCTAssertEqual(exercise.movementPattern, .horizontalPush)
        XCTAssertEqual(exercise.primaryMuscles, [.chest])
        XCTAssertTrue(exercise.secondaryMuscles.contains(.triceps))
        XCTAssertTrue(exercise.equipmentRequired.contains(.barbell))
    }
    
    func testExercise_DefaultValues() {
        let exercise = Exercise(
            name: "Test",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipmentRequired: []
        )
        
        XCTAssertTrue(exercise.isCompound)
        XCTAssertNil(exercise.instructions)
        XCTAssertEqual(exercise.defaultProgressionType, .topSetBackoff)
    }
    
    func testExercise_AllMuscles() {
        let exercise = Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .frontDelt],
            equipmentRequired: [.barbell, .bench]
        )
        
        let allMuscles = exercise.allMuscles
        XCTAssertEqual(allMuscles.count, 3)
        XCTAssertTrue(allMuscles.contains(.chest))
        XCTAssertTrue(allMuscles.contains(.triceps))
    }
    
    func testExercise_DefaultWeightIncrement() {
        let barbellExercise = Exercise(
            name: "Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            equipmentRequired: [.barbell, .rack],
            isCompound: true
        )
        XCTAssertEqual(barbellExercise.defaultWeightIncrement, 2.5)
        
        let dumbbellExercise = Exercise(
            name: "DB Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            equipmentRequired: [.dumbbell],
            isCompound: false
        )
        XCTAssertEqual(dumbbellExercise.defaultWeightIncrement, 2.0)
    }
}

// MARK: - Equipment Enum Tests

final class EquipmentEnumTests: XCTestCase {
    
    func testEquipment_AllCases() {
        XCTAssertTrue(Equipment.allCases.contains(.barbell))
        XCTAssertTrue(Equipment.allCases.contains(.dumbbell))
        XCTAssertTrue(Equipment.allCases.contains(.bodyweight))
        XCTAssertTrue(Equipment.allCases.contains(.machine))
        XCTAssertTrue(Equipment.allCases.contains(.cable))
        XCTAssertTrue(Equipment.allCases.contains(.bench))
        XCTAssertTrue(Equipment.allCases.contains(.rack))
    }
    
    func testEquipment_Identifiable() {
        let equipment = Equipment.barbell
        XCTAssertEqual(equipment.id, equipment.rawValue)
    }
}

// MARK: - MovementPattern Enum Tests

final class MovementPatternEnumTests: XCTestCase {
    
    func testMovementPattern_AllCases() {
        let allCases = MovementPattern.allCases
        XCTAssertTrue(allCases.contains(.horizontalPush))
        XCTAssertTrue(allCases.contains(.horizontalPull))
        XCTAssertTrue(allCases.contains(.verticalPush))
        XCTAssertTrue(allCases.contains(.verticalPull))
        XCTAssertTrue(allCases.contains(.squat))
        XCTAssertTrue(allCases.contains(.hinge))
        XCTAssertTrue(allCases.contains(.lunge))
    }
}

// MARK: - Goal Enum Tests

final class GoalEnumTests: XCTestCase {
    
    func testGoal_AllCases() {
        XCTAssertTrue(Goal.allCases.contains(.strength))
        XCTAssertTrue(Goal.allCases.contains(.hypertrophy))
        XCTAssertTrue(Goal.allCases.contains(.both))
    }
    
    func testGoal_RawValues() {
        XCTAssertEqual(Goal.strength.rawValue, "Strength")
        XCTAssertEqual(Goal.hypertrophy.rawValue, "Hypertrophy")
        XCTAssertEqual(Goal.both.rawValue, "Both")
    }
}

// MARK: - Location Enum Tests

final class LocationEnumTests: XCTestCase {
    
    func testLocation_AllCases() {
        XCTAssertTrue(Location.allCases.contains(.gym))
        XCTAssertTrue(Location.allCases.contains(.home))
        XCTAssertTrue(Location.allCases.contains(.mixed))
    }
    
    func testLocation_RawValues() {
        XCTAssertEqual(Location.gym.rawValue, "Gym")
        XCTAssertEqual(Location.home.rawValue, "Home")
        XCTAssertEqual(Location.mixed.rawValue, "Mixed")
    }
}

// MARK: - SetType Enum Tests

final class SetTypeEnumTests: XCTestCase {
    
    func testSetType_AllCases() {
        XCTAssertTrue(SetType.allCases.contains(.warmup))
        XCTAssertTrue(SetType.allCases.contains(.working))
        XCTAssertTrue(SetType.allCases.contains(.topSet))
        XCTAssertTrue(SetType.allCases.contains(.backoff))
    }
    
    func testSetType_RawValues() {
        XCTAssertEqual(SetType.warmup.rawValue, "Warmup")
        XCTAssertEqual(SetType.working.rawValue, "Working")
        XCTAssertEqual(SetType.topSet.rawValue, "Top Set")
        XCTAssertEqual(SetType.backoff.rawValue, "Backoff")
    }
}

// MARK: - UnitSystem Enum Tests

final class UnitSystemEnumTests: XCTestCase {
    
    func testUnitSystem_AllCases() {
        XCTAssertTrue(UnitSystem.allCases.contains(.metric))
        XCTAssertTrue(UnitSystem.allCases.contains(.imperial))
    }
    
    func testUnitSystem_WeightUnit() {
        XCTAssertEqual(UnitSystem.metric.weightUnit, "kg")
        XCTAssertEqual(UnitSystem.imperial.weightUnit, "lbs")
    }
    
    func testUnitSystem_SmallIncrement() {
        XCTAssertEqual(UnitSystem.metric.smallIncrement, 2.5)
        XCTAssertEqual(UnitSystem.imperial.smallIncrement, 5.0)
    }
}

// MARK: - ProgressionType Enum Tests

final class ProgressionTypeEnumTests: XCTestCase {
    
    func testProgressionType_AllCases() {
        XCTAssertTrue(ProgressionType.allCases.contains(.topSetBackoff))
        XCTAssertTrue(ProgressionType.allCases.contains(.doubleProgression))
        XCTAssertTrue(ProgressionType.allCases.contains(.straightSets))
    }
    
    func testProgressionType_RawValues() {
        XCTAssertEqual(ProgressionType.topSetBackoff.rawValue, "Top Set + Backoffs")
        XCTAssertEqual(ProgressionType.doubleProgression.rawValue, "Double Progression")
        XCTAssertEqual(ProgressionType.straightSets.rawValue, "Straight Sets")
    }
}

// MARK: - Readiness Tests

final class ReadinessTests: XCTestCase {
    
    func testReadiness_Default() {
        let readiness = Readiness.default
        
        XCTAssertEqual(readiness.energy, .ok)
        XCTAssertEqual(readiness.soreness, .none)
        XCTAssertEqual(readiness.timeAvailable, 60)
    }
    
    func testReadiness_ShouldReduceIntensity() {
        let lowEnergy = Readiness(energy: .low, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(lowEnergy.shouldReduceIntensity)
        
        let highSoreness = Readiness(energy: .ok, soreness: .high, timeAvailable: 60)
        XCTAssertTrue(highSoreness.shouldReduceIntensity)
        
        let normal = Readiness(energy: .ok, soreness: .none, timeAvailable: 60)
        XCTAssertFalse(normal.shouldReduceIntensity)
    }
    
    func testReadiness_ShouldIncreaseIntensity() {
        let optimal = Readiness(energy: .high, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(optimal.shouldIncreaseIntensity)
        
        let subOptimal = Readiness(energy: .high, soreness: .mild, timeAvailable: 60)
        XCTAssertFalse(subOptimal.shouldIncreaseIntensity)
    }
}

// MARK: - EnergyLevel Enum Tests

final class EnergyLevelEnumTests: XCTestCase {
    
    func testEnergyLevel_AllCases() {
        XCTAssertTrue(EnergyLevel.allCases.contains(.low))
        XCTAssertTrue(EnergyLevel.allCases.contains(.ok))
        XCTAssertTrue(EnergyLevel.allCases.contains(.high))
    }
}

// MARK: - SorenessLevel Enum Tests

final class SorenessLevelEnumTests: XCTestCase {
    
    func testSorenessLevel_AllCases() {
        XCTAssertTrue(SorenessLevel.allCases.contains(.none))
        XCTAssertTrue(SorenessLevel.allCases.contains(.mild))
        XCTAssertTrue(SorenessLevel.allCases.contains(.high))
    }
    
    func testSorenessLevel_RawValues() {
        XCTAssertEqual(SorenessLevel.none.rawValue, "None")
        XCTAssertEqual(SorenessLevel.mild.rawValue, "Mild")
        XCTAssertEqual(SorenessLevel.high.rawValue, "High")
    }
}

// MARK: - LLMProviderType Enum Tests

final class LLMProviderTypeEnumTests: XCTestCase {
    
    func testLLMProviderType_AllCases() {
        XCTAssertTrue(LLMProviderType.allCases.contains(.offline))
        XCTAssertTrue(LLMProviderType.allCases.contains(.openai))
        XCTAssertTrue(LLMProviderType.allCases.contains(.claude))
    }
    
    func testLLMProviderType_DisplayName() {
        XCTAssertEqual(LLMProviderType.offline.displayName, "Offline Mode")
        XCTAssertEqual(LLMProviderType.openai.displayName, "ChatGPT (OpenAI)")
        XCTAssertEqual(LLMProviderType.claude.displayName, "Claude (Anthropic)")
    }
    
    func testLLMProviderType_RequiresAPIKey() {
        XCTAssertFalse(LLMProviderType.offline.requiresAPIKey)
        XCTAssertTrue(LLMProviderType.openai.requiresAPIKey)
        XCTAssertTrue(LLMProviderType.claude.requiresAPIKey)
    }
}
