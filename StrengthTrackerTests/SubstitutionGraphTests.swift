import XCTest
@testable import StrengthTracker

final class SubstitutionGraphTests: XCTestCase {
    
    var graph: SubstitutionGraph!
    
    override func setUp() async throws {
        graph = SubstitutionGraph.shared
    }
    
    // MARK: - Find Substitutes Tests
    
    func testFindSubstitutes_ReturnsValidSubstitutes() async {
        let exercises = createTestExercises()
        let availableEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .bodyweight]
        
        let substitutes = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: availableEquipment,
            allExercises: exercises,
            painFlags: [],
            limit: 3
        )
        
        XCTAssertFalse(substitutes.isEmpty, "Should find substitutes for Bench Press")
        XCTAssertLessThanOrEqual(substitutes.count, 3, "Should respect limit")
    }
    
    func testFindSubstitutes_UnknownExercise_ReturnsEmpty() async {
        let exercises = createTestExercises()
        let availableEquipment: Set<Equipment> = [.barbell, .dumbbell]
        
        let substitutes = await graph.findSubstitutes(
            for: "Unknown Exercise",
            availableEquipment: availableEquipment,
            allExercises: exercises,
            painFlags: [],
            limit: 3
        )
        
        XCTAssertTrue(substitutes.isEmpty, "Should return empty for unknown exercise")
    }
    
    func testFindSubstitutes_FiltersUnavailableEquipment() async {
        let exercises = createTestExercises()
        let availableEquipment: Set<Equipment> = [.dumbbell, .bodyweight] // No barbell
        
        let substitutes = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: availableEquipment,
            allExercises: exercises,
            painFlags: [],
            limit: 5
        )
        
        // Should not include barbell exercises
        for (sub, _) in substitutes {
            XCTAssertFalse(
                sub.equipmentRequired.contains(.barbell),
                "\(sub.name) requires barbell but shouldn't be included"
            )
        }
    }
    
    func testFindSubstitutes_RespectsLimit() async {
        let exercises = createTestExercises()
        let availableEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .bodyweight, .cable, .machine]
        
        let substitutes = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: availableEquipment,
            allExercises: exercises,
            painFlags: [],
            limit: 2
        )
        
        XCTAssertLessThanOrEqual(substitutes.count, 2, "Should respect limit of 2")
    }
    
    // MARK: - Get Best Substitute Tests
    
    func testGetBestSubstitute_ReturnsTopOption() async {
        let exercises = createTestExercises()
        let availableEquipment: Set<Equipment> = [.dumbbell, .bench, .bodyweight]
        
        guard let benchPress = exercises.first(where: { $0.name == "Bench Press" }) else {
            XCTFail("Test exercises should include Bench Press")
            return
        }
        
        let result = await graph.getBestSubstitute(
            for: benchPress,
            availableEquipment: availableEquipment,
            allExercises: exercises,
            painFlags: []
        )
        
        XCTAssertNotNil(result, "Should find a substitute for Bench Press")
    }
    
    // MARK: - Needs Substitution Tests
    
    func testNeedsSubstitution_EquipmentMissing() async {
        let exercise = Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .frontDelt],
            equipmentRequired: [.barbell, .bench]
        )
        
        let availableEquipment: Set<Equipment> = [.dumbbell] // Missing barbell and bench
        
        let reason = await graph.needsSubstitution(
            exercise: exercise,
            availableEquipment: availableEquipment,
            painFlags: []
        )
        
        XCTAssertEqual(reason, SubstitutionGraph.SubstitutionReason.equipmentMissing)
    }
    
    func testNeedsSubstitution_NoSubstitutionNeeded() async {
        let exercise = Exercise(
            name: "Push-ups",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.bodyweight]
        )
        
        let availableEquipment: Set<Equipment> = [.bodyweight, .barbell, .dumbbell]
        
        let reason = await graph.needsSubstitution(
            exercise: exercise,
            availableEquipment: availableEquipment,
            painFlags: []
        )
        
        XCTAssertNil(reason, "Should not need substitution when equipment available")
    }
    
    // MARK: - Helper Methods
    
    private func createTestExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Bench Press",
                movementPattern: .horizontalPush,
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps, .frontDelt],
                equipmentRequired: [.barbell, .bench]
            ),
            Exercise(
                name: "Dumbbell Bench Press",
                movementPattern: .horizontalPush,
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps, .frontDelt],
                equipmentRequired: [.dumbbell, .bench]
            ),
            Exercise(
                name: "Push-ups",
                movementPattern: .horizontalPush,
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps],
                equipmentRequired: [.bodyweight]
            ),
            Exercise(
                name: "Floor Press",
                movementPattern: .horizontalPush,
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps],
                equipmentRequired: [.dumbbell]
            ),
            Exercise(
                name: "Machine Chest Press",
                movementPattern: .horizontalPush,
                primaryMuscles: [.chest],
                secondaryMuscles: [.triceps],
                equipmentRequired: [.machine]
            ),
            Exercise(
                name: "Barbell Squat",
                movementPattern: .squat,
                primaryMuscles: [.quads, .glutes],
                secondaryMuscles: [.hamstrings],
                equipmentRequired: [.barbell, .rack]
            ),
            Exercise(
                name: "Goblet Squat",
                movementPattern: .squat,
                primaryMuscles: [.quads, .glutes],
                secondaryMuscles: [.core],
                equipmentRequired: [.dumbbell]
            )
        ]
    }
}

// MARK: - Split Enum Tests

final class SplitEnumTests: XCTestCase {
    
    func testSplit_AllCases() {
        XCTAssertTrue(Split.allCases.contains(.upperLower))
        XCTAssertTrue(Split.allCases.contains(.ppl))
        XCTAssertTrue(Split.allCases.contains(.fullBody))
        XCTAssertTrue(Split.allCases.contains(.custom))
    }
    
    func testSplit_DaysPerWeek() {
        XCTAssertEqual(Split.upperLower.daysPerWeek, 4)
        XCTAssertEqual(Split.ppl.daysPerWeek, 6)
        XCTAssertEqual(Split.fullBody.daysPerWeek, 3)
        XCTAssertEqual(Split.custom.daysPerWeek, 0)
    }
    
    func testSplit_RawValues() {
        XCTAssertEqual(Split.upperLower.rawValue, "Upper/Lower")
        XCTAssertEqual(Split.ppl.rawValue, "Push/Pull/Legs")
        XCTAssertEqual(Split.fullBody.rawValue, "Full Body")
        XCTAssertEqual(Split.custom.rawValue, "Custom")
    }
}

// MARK: - BodyPart Enum Tests

final class BodyPartEnumTests: XCTestCase {
    
    func testBodyPart_AllCases() {
        XCTAssertTrue(BodyPart.allCases.contains(.chest))
        XCTAssertTrue(BodyPart.allCases.contains(.back))
        XCTAssertTrue(BodyPart.allCases.contains(.shoulders))
        XCTAssertTrue(BodyPart.allCases.contains(.arms))
        XCTAssertTrue(BodyPart.allCases.contains(.legs))
        XCTAssertTrue(BodyPart.allCases.contains(.core))
    }
    
    func testBodyPart_RawValues() {
        XCTAssertEqual(BodyPart.chest.rawValue, "Chest")
        XCTAssertEqual(BodyPart.back.rawValue, "Back")
        XCTAssertEqual(BodyPart.shoulders.rawValue, "Shoulders")
        XCTAssertEqual(BodyPart.arms.rawValue, "Arms")
        XCTAssertEqual(BodyPart.legs.rawValue, "Legs")
        XCTAssertEqual(BodyPart.core.rawValue, "Core")
    }
}

// MARK: - Muscle Enum Tests

final class MuscleEnumTests: XCTestCase {
    
    func testMuscle_BodyPartMapping() {
        XCTAssertEqual(Muscle.chest.bodyPart, .chest)
        XCTAssertEqual(Muscle.lats.bodyPart, .back)
        XCTAssertEqual(Muscle.frontDelt.bodyPart, .shoulders)
        XCTAssertEqual(Muscle.sideDelt.bodyPart, .shoulders)
        XCTAssertEqual(Muscle.rearDelt.bodyPart, .shoulders)
        XCTAssertEqual(Muscle.biceps.bodyPart, .arms)
        XCTAssertEqual(Muscle.triceps.bodyPart, .arms)
        XCTAssertEqual(Muscle.quads.bodyPart, .legs)
        XCTAssertEqual(Muscle.hamstrings.bodyPart, .legs)
        XCTAssertEqual(Muscle.glutes.bodyPart, .legs)
        XCTAssertEqual(Muscle.calves.bodyPart, .legs)
        XCTAssertEqual(Muscle.core.bodyPart, .core)
    }
    
    func testMuscle_AllCases() {
        XCTAssertGreaterThan(Muscle.allCases.count, 0)
        XCTAssertTrue(Muscle.allCases.contains(.chest))
        XCTAssertTrue(Muscle.allCases.contains(.lats))
        XCTAssertTrue(Muscle.allCases.contains(.quads))
    }
}

// MARK: - PainSeverity Enum Tests

final class PainSeverityEnumTests: XCTestCase {
    
    func testPainSeverity_AllCases() {
        XCTAssertTrue(PainSeverity.allCases.contains(.mild))
        XCTAssertTrue(PainSeverity.allCases.contains(.moderate))
        XCTAssertTrue(PainSeverity.allCases.contains(.severe))
    }
    
    func testPainSeverity_RawValues() {
        XCTAssertEqual(PainSeverity.mild.rawValue, "Mild")
        XCTAssertEqual(PainSeverity.moderate.rawValue, "Moderate")
        XCTAssertEqual(PainSeverity.severe.rawValue, "Severe")
    }
}
