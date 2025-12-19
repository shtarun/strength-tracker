import XCTest

/// Unit tests for SubstitutionGraph - Exercise substitution logic
/// Tests equipment-based and pain-aware exercise substitutions
final class SubstitutionGraphTests: XCTestCase {

    // MARK: - Test Helpers

    private func createExercise(
        name: String,
        equipment: [Equipment] = [.barbell],
        primaryMuscles: [Muscle] = [.chest]
    ) -> Exercise {
        return Exercise(
            name: name,
            movementPattern: .horizontalPush,
            primaryMuscles: primaryMuscles,
            equipmentRequired: equipment
        )
    }

    private var exerciseLibrary: [Exercise] {
        [
            // Horizontal Push
            createExercise(name: "Bench Press", equipment: [.barbell, .bench], primaryMuscles: [.chest, .triceps]),
            createExercise(name: "Dumbbell Bench Press", equipment: [.dumbbell, .bench], primaryMuscles: [.chest, .triceps]),
            createExercise(name: "Floor Press", equipment: [.barbell], primaryMuscles: [.chest, .triceps]),
            createExercise(name: "Push-ups", equipment: [.bodyweight], primaryMuscles: [.chest, .triceps]),
            createExercise(name: "Machine Chest Press", equipment: [.machine], primaryMuscles: [.chest, .triceps]),

            // Vertical Push
            createExercise(name: "Overhead Press", equipment: [.barbell], primaryMuscles: [.frontDelt, .triceps]),
            createExercise(name: "Dumbbell Shoulder Press", equipment: [.dumbbell], primaryMuscles: [.frontDelt, .triceps]),

            // Vertical Pull
            createExercise(name: "Pull-ups", equipment: [.pullUpBar], primaryMuscles: [.lats, .biceps]),
            createExercise(name: "Lat Pulldown", equipment: [.cable], primaryMuscles: [.lats, .biceps]),
            createExercise(name: "Banded Pull-ups", equipment: [.bands, .pullUpBar], primaryMuscles: [.lats, .biceps]),

            // Horizontal Pull
            createExercise(name: "Barbell Row", equipment: [.barbell], primaryMuscles: [.upperBack, .lats]),
            createExercise(name: "Dumbbell Row", equipment: [.dumbbell], primaryMuscles: [.upperBack, .lats]),
            createExercise(name: "Chest Supported Row", equipment: [.dumbbell, .bench], primaryMuscles: [.upperBack, .lats]),
            createExercise(name: "Cable Row", equipment: [.cable], primaryMuscles: [.upperBack, .lats]),
            createExercise(name: "Inverted Row", equipment: [.bodyweight], primaryMuscles: [.upperBack, .lats]),

            // Squat Pattern
            createExercise(name: "Barbell Squat", equipment: [.barbell, .rack], primaryMuscles: [.quads, .glutes]),
            createExercise(name: "Goblet Squat", equipment: [.dumbbell], primaryMuscles: [.quads, .glutes]),
            createExercise(name: "Leg Press", equipment: [.machine], primaryMuscles: [.quads, .glutes]),
            createExercise(name: "Bulgarian Split Squat", equipment: [.dumbbell], primaryMuscles: [.quads, .glutes]),

            // Hinge Pattern
            createExercise(name: "Deadlift", equipment: [.barbell], primaryMuscles: [.hamstrings, .glutes, .lowerBack]),
            createExercise(name: "Romanian Deadlift", equipment: [.barbell], primaryMuscles: [.hamstrings, .glutes]),
            createExercise(name: "Dumbbell Romanian Deadlift", equipment: [.dumbbell], primaryMuscles: [.hamstrings, .glutes]),

            // Arms
            createExercise(name: "Barbell Curl", equipment: [.barbell], primaryMuscles: [.biceps]),
            createExercise(name: "Dumbbell Curl", equipment: [.dumbbell], primaryMuscles: [.biceps]),
            createExercise(name: "Cable Curl", equipment: [.cable], primaryMuscles: [.biceps]),
            createExercise(name: "Band Curl", equipment: [.bands], primaryMuscles: [.biceps]),
            createExercise(name: "Tricep Pushdown", equipment: [.cable], primaryMuscles: [.triceps]),
        ]
    }

    // MARK: - Substitution Reason Tests

    func testSubstitutionReasonRawValues() {
        XCTAssertEqual(SubstitutionGraph.SubstitutionReason.equipmentMissing.rawValue, "Equipment not available")
        XCTAssertEqual(SubstitutionGraph.SubstitutionReason.painFlag.rawValue, "Pain flag for this movement")
        XCTAssertEqual(SubstitutionGraph.SubstitutionReason.timeConstraint.rawValue, "Time constraint")
        XCTAssertEqual(SubstitutionGraph.SubstitutionReason.userPreference.rawValue, "User preference")
    }

    // MARK: - Equipment-Based Substitution Tests

    func testFindSubstitutesWithFullEquipment() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .rack, .cable, .machine, .pullUpBar, .bodyweight]

        let subs = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        XCTAssertGreaterThan(subs.count, 0, "Should find substitutes with full equipment")
    }

    func testFindSubstitutesWithLimitedEquipment() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let limitedEquipment: Set<Equipment> = [.dumbbell, .bodyweight]

        let subs = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: limitedEquipment,
            allExercises: exercises
        )

        // Should find dumbbell or bodyweight alternatives
        for (exercise, _) in subs {
            let required = Set(exercise.equipmentRequired)
            XCTAssertTrue(required.isSubset(of: limitedEquipment),
                          "\(exercise.name) requires equipment not available")
        }
    }

    func testFindSubstitutesWithNoEquipment() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let noEquipment: Set<Equipment> = []

        let subs = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: noEquipment,
            allExercises: exercises
        )

        XCTAssertEqual(subs.count, 0, "No substitutes should be found without equipment")
    }

    func testFindSubstitutesForUnknownExercise() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .rack, .cable, .machine]

        let subs = await graph.findSubstitutes(
            for: "Unknown Exercise XYZ",
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        XCTAssertEqual(subs.count, 0, "Unknown exercise should return empty substitutes")
    }

    func testSubstitutesRespectLimit() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .rack, .cable, .machine, .pullUpBar, .bodyweight]

        let subs = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: fullEquipment,
            allExercises: exercises,
            limit: 2
        )

        XCTAssertLessThanOrEqual(subs.count, 2, "Should respect limit parameter")
    }

    // MARK: - Best Substitute Tests

    func testGetBestSubstitute() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .rack, .cable, .machine, .pullUpBar, .bodyweight]

        let benchPress = exercises.first { $0.name == "Bench Press" }!

        let result = await graph.getBestSubstitute(
            for: benchPress,
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        XCTAssertNotNil(result, "Should find best substitute for Bench Press")
        if let (substitute, _) = result {
            XCTAssertNotEqual(substitute.name, "Bench Press", "Substitute should be different exercise")
        }
    }

    func testGetBestSubstituteWithLimitedEquipment() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let limitedEquipment: Set<Equipment> = [.bodyweight]

        let benchPress = exercises.first { $0.name == "Bench Press" }!

        let result = await graph.getBestSubstitute(
            for: benchPress,
            availableEquipment: limitedEquipment,
            allExercises: exercises
        )

        if let (substitute, _) = result {
            XCTAssertTrue(substitute.equipmentRequired.allSatisfy { limitedEquipment.contains($0) },
                          "Substitute should only require available equipment")
        }
    }

    // MARK: - Needs Substitution Tests

    func testNeedsSubstitutionEquipmentMissing() async {
        let graph = SubstitutionGraph.shared

        let benchPress = createExercise(name: "Bench Press", equipment: [.barbell, .bench])
        let availableEquipment: Set<Equipment> = [.dumbbell] // Missing barbell and bench

        let reason = await graph.needsSubstitution(
            exercise: benchPress,
            availableEquipment: availableEquipment
        )

        XCTAssertEqual(reason, .equipmentMissing)
    }

    func testNeedsSubstitutionEquipmentAvailable() async {
        let graph = SubstitutionGraph.shared

        let benchPress = createExercise(name: "Bench Press", equipment: [.barbell, .bench])
        let availableEquipment: Set<Equipment> = [.barbell, .bench, .dumbbell]

        let reason = await graph.needsSubstitution(
            exercise: benchPress,
            availableEquipment: availableEquipment
        )

        XCTAssertNil(reason, "Should not need substitution when equipment is available")
    }

    func testNeedsSubstitutionBodyweightAlwaysAvailable() async {
        let graph = SubstitutionGraph.shared

        let pushups = createExercise(name: "Push-ups", equipment: [.bodyweight])
        let availableEquipment: Set<Equipment> = [.bodyweight]

        let reason = await graph.needsSubstitution(
            exercise: pushups,
            availableEquipment: availableEquipment
        )

        XCTAssertNil(reason, "Bodyweight exercises should work with bodyweight available")
    }

    // MARK: - Movement Pattern Substitution Tests

    func testHorizontalPushSubstitutes() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .cable, .machine, .bodyweight]

        let subs = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        // All substitutes should be chest/pushing exercises
        for (exercise, _) in subs {
            XCTAssertTrue(exercise.primaryMuscles.contains(.chest) || exercise.primaryMuscles.contains(.triceps),
                          "\(exercise.name) should target similar muscles")
        }
    }

    func testVerticalPullSubstitutes() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .cable, .machine, .bodyweight, .pullUpBar, .bands]

        let subs = await graph.findSubstitutes(
            for: "Pull-ups",
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        // All substitutes should be back/pulling exercises
        for (exercise, _) in subs {
            XCTAssertTrue(exercise.primaryMuscles.contains(.lats) || exercise.primaryMuscles.contains(.biceps),
                          "\(exercise.name) should target similar muscles")
        }
    }

    func testSquatPatternSubstitutes() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .bench, .rack, .machine]

        let subs = await graph.findSubstitutes(
            for: "Barbell Squat",
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        // All substitutes should target quads/glutes
        for (exercise, _) in subs {
            XCTAssertTrue(exercise.primaryMuscles.contains(.quads) || exercise.primaryMuscles.contains(.glutes),
                          "\(exercise.name) should target similar muscles")
        }
    }

    func testHingePatternSubstitutes() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell]

        let subs = await graph.findSubstitutes(
            for: "Deadlift",
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        // All substitutes should target hamstrings/glutes
        for (exercise, _) in subs {
            XCTAssertTrue(exercise.primaryMuscles.contains(.hamstrings) || exercise.primaryMuscles.contains(.glutes),
                          "\(exercise.name) should target similar muscles")
        }
    }

    // MARK: - Isolation Exercise Substitutes

    func testBicepCurlSubstitutes() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary
        let fullEquipment: Set<Equipment> = [.barbell, .dumbbell, .cable, .bands]

        let subs = await graph.findSubstitutes(
            for: "Barbell Curl",
            availableEquipment: fullEquipment,
            allExercises: exercises
        )

        XCTAssertGreaterThan(subs.count, 0, "Should find curl substitutes")

        for (exercise, _) in subs {
            XCTAssertTrue(exercise.primaryMuscles.contains(.biceps),
                          "\(exercise.name) should target biceps")
        }
    }

    // MARK: - Substitution Structure Tests

    func testSubstitutionStructureCodable() throws {
        let substitution = SubstitutionGraph.Substitution(
            originalExercise: "Bench Press",
            substituteExercise: "Dumbbell Bench Press",
            reason: .equipmentMissing
        )

        let encoded = try JSONEncoder().encode(substitution)
        let decoded = try JSONDecoder().decode(SubstitutionGraph.Substitution.self, from: encoded)

        XCTAssertEqual(decoded.originalExercise, "Bench Press")
        XCTAssertEqual(decoded.substituteExercise, "Dumbbell Bench Press")
        XCTAssertEqual(decoded.reason, .equipmentMissing)
    }

    // MARK: - Home vs Gym Equipment Tests

    func testHomeGymSubstitutions() async {
        let graph = SubstitutionGraph.shared
        let exercises = exerciseLibrary

        // Typical home gym equipment
        let homeEquipment: Set<Equipment> = [.dumbbell, .bodyweight, .bands, .pullUpBar]

        // Should find home-friendly substitutes for barbell exercises
        let benchSubs = await graph.findSubstitutes(
            for: "Bench Press",
            availableEquipment: homeEquipment,
            allExercises: exercises
        )

        XCTAssertGreaterThan(benchSubs.count, 0, "Should find home substitutes for Bench Press")

        // All substitutes should work with home equipment
        for (exercise, _) in benchSubs {
            let required = Set(exercise.equipmentRequired)
            XCTAssertTrue(required.isSubset(of: homeEquipment),
                          "\(exercise.name) should only need home equipment")
        }
    }
}
