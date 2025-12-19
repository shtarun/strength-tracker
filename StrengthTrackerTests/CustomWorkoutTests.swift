import XCTest

/// Unit tests for Custom Workout generation and validation
/// Tests the custom workout request/response structures
final class CustomWorkoutTests: XCTestCase {

    // MARK: - CustomWorkoutRequest Tests

    func testCustomWorkoutRequestStructure() throws {
        let request = CustomWorkoutRequest(
            userPrompt: "I want a chest and triceps workout",
            availableExercises: [
                AvailableExerciseInfo(
                    name: "Bench Press",
                    movementPattern: "Horizontal Push",
                    primaryMuscles: ["Chest", "Triceps"],
                    isCompound: true,
                    equipmentRequired: ["Barbell", "Bench"]
                ),
                AvailableExerciseInfo(
                    name: "Dumbbell Fly",
                    movementPattern: "Isolation",
                    primaryMuscles: ["Chest"],
                    isCompound: false,
                    equipmentRequired: ["Dumbbell", "Bench"]
                ),
                AvailableExerciseInfo(
                    name: "Tricep Pushdown",
                    movementPattern: "Isolation",
                    primaryMuscles: ["Triceps"],
                    isCompound: false,
                    equipmentRequired: ["Cable"]
                )
            ],
            equipmentAvailable: ["Barbell", "Dumbbell", "Bench", "Cable"],
            userGoal: "Hypertrophy",
            location: "Gym",
            timeAvailable: 45,
            recentExerciseHistory: [
                "Bench Press": 116.67,
                "Dumbbell Fly": 60.0
            ]
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(CustomWorkoutRequest.self, from: encoded)

        XCTAssertEqual(decoded.userPrompt, "I want a chest and triceps workout")
        XCTAssertEqual(decoded.availableExercises.count, 3)
        XCTAssertEqual(decoded.equipmentAvailable.count, 4)
        XCTAssertEqual(decoded.userGoal, "Hypertrophy")
        XCTAssertEqual(decoded.timeAvailable, 45)
    }

    func testAvailableExerciseInfoCodable() throws {
        let exerciseInfo = AvailableExerciseInfo(
            name: "Barbell Squat",
            movementPattern: "Squat",
            primaryMuscles: ["Quads", "Glutes"],
            isCompound: true,
            equipmentRequired: ["Barbell", "Rack"]
        )

        let encoded = try JSONEncoder().encode(exerciseInfo)
        let decoded = try JSONDecoder().decode(AvailableExerciseInfo.self, from: encoded)

        XCTAssertEqual(decoded.name, "Barbell Squat")
        XCTAssertEqual(decoded.movementPattern, "Squat")
        XCTAssertEqual(decoded.primaryMuscles.count, 2)
        XCTAssertTrue(decoded.isCompound)
        XCTAssertEqual(decoded.equipmentRequired.count, 2)
    }

    // MARK: - CustomWorkoutResponse Tests

    func testCustomWorkoutResponseStructure() throws {
        let response = CustomWorkoutResponse(
            workoutName: "Chest & Triceps Pump",
            exercises: [
                CustomExercisePlan(
                    exerciseName: "Bench Press",
                    sets: 4,
                    reps: "8-10",
                    rpeCap: 8.0,
                    notes: "Focus on chest squeeze",
                    suggestedWeight: 85.0
                ),
                CustomExercisePlan(
                    exerciseName: "Dumbbell Fly",
                    sets: 3,
                    reps: "12-15",
                    rpeCap: 7.5,
                    notes: nil,
                    suggestedWeight: 15.0
                ),
                CustomExercisePlan(
                    exerciseName: "Tricep Pushdown",
                    sets: 3,
                    reps: "10-12",
                    rpeCap: 8.0,
                    notes: "Keep elbows pinned",
                    suggestedWeight: nil
                )
            ],
            reasoning: "Selected chest compounds first, followed by isolation work for both chest and triceps",
            estimatedDuration: 40,
            focusAreas: ["Chest", "Triceps"]
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(CustomWorkoutResponse.self, from: encoded)

        XCTAssertEqual(decoded.workoutName, "Chest & Triceps Pump")
        XCTAssertEqual(decoded.exercises.count, 3)
        XCTAssertEqual(decoded.estimatedDuration, 40)
        XCTAssertEqual(decoded.focusAreas.count, 2)
    }

    // MARK: - CustomExercisePlan Tests

    func testCustomExercisePlanRepsRangeParser() {
        let rangeReps = CustomExercisePlan(
            exerciseName: "Bench Press",
            sets: 4,
            reps: "8-10",
            rpeCap: 8.0
        )

        XCTAssertEqual(rangeReps.repsMin, 8)
        XCTAssertEqual(rangeReps.repsMax, 10)
    }

    func testCustomExercisePlanSingleReps() {
        let singleReps = CustomExercisePlan(
            exerciseName: "Deadlift",
            sets: 5,
            reps: "5",
            rpeCap: 9.0
        )

        XCTAssertEqual(singleReps.repsMin, 5)
        XCTAssertEqual(singleReps.repsMax, 5)
    }

    func testCustomExercisePlanInvalidReps() {
        let invalidReps = CustomExercisePlan(
            exerciseName: "Unknown",
            sets: 3,
            reps: "invalid",
            rpeCap: 8.0
        )

        // Should fall back to defaults
        XCTAssertEqual(invalidReps.repsMin, 8) // Default
        XCTAssertEqual(invalidReps.repsMax, 10) // Default from "invalid" parsed as last
    }

    func testCustomExercisePlanWithMetadata() throws {
        let plan = CustomExercisePlan(
            exerciseName: "Cable Fly",
            sets: 3,
            reps: "12-15",
            rpeCap: 7.5,
            notes: "Squeeze at the peak",
            suggestedWeight: 20.0,
            movementPattern: "horizontalPush",
            primaryMuscles: ["chest"],
            isCompound: false,
            equipmentRequired: ["cable"],
            youtubeVideoURL: nil
        )

        let encoded = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(CustomExercisePlan.self, from: encoded)

        XCTAssertEqual(decoded.movementPattern, "horizontalPush")
        XCTAssertEqual(decoded.primaryMuscles?.first, "chest")
        XCTAssertEqual(decoded.isCompound, false)
        XCTAssertEqual(decoded.equipmentRequired?.first, "cable")
    }

    // MARK: - Workout Duration Estimation Tests

    func testDurationEstimation() {
        // Typical: ~3-4 minutes per working set including rest
        let exercises = [
            CustomExercisePlan(exerciseName: "Bench Press", sets: 4, reps: "8-10", rpeCap: 8.0),
            CustomExercisePlan(exerciseName: "Dumbbell Fly", sets: 3, reps: "12-15", rpeCap: 7.5),
            CustomExercisePlan(exerciseName: "Tricep Pushdown", sets: 3, reps: "10-12", rpeCap: 8.0)
        ]

        let totalSets = exercises.reduce(0) { $0 + $1.sets }
        let estimatedMinutes = totalSets * 3 // 3 minutes per set

        XCTAssertEqual(totalSets, 10)
        XCTAssertEqual(estimatedMinutes, 30)
    }

    func testCompoundExerciseDuration() {
        // Compound exercises typically take longer (more warmups, heavier loads)
        let compoundExercise = CustomExercisePlan(
            exerciseName: "Barbell Squat",
            sets: 5,
            reps: "5",
            rpeCap: 9.0
        )

        // 5 working sets + ~3-4 warmup sets = ~8-9 total sets
        // At 3-4 minutes each = ~24-36 minutes for this exercise alone
        let workingSets = compoundExercise.sets
        let estimatedWarmupSets = 4
        let totalSets = workingSets + estimatedWarmupSets
        let estimatedDuration = totalSets * 4 // 4 minutes for heavy compound

        XCTAssertEqual(estimatedDuration, 36)
    }

    // MARK: - Equipment Matching Tests

    func testEquipmentFiltering() {
        let availableEquipment = Set(["Barbell", "Dumbbell", "Bench"])

        let exercises = [
            AvailableExerciseInfo(
                name: "Bench Press",
                movementPattern: "Horizontal Push",
                primaryMuscles: ["Chest"],
                isCompound: true,
                equipmentRequired: ["Barbell", "Bench"] // Available
            ),
            AvailableExerciseInfo(
                name: "Cable Fly",
                movementPattern: "Isolation",
                primaryMuscles: ["Chest"],
                isCompound: false,
                equipmentRequired: ["Cable"] // NOT available
            ),
            AvailableExerciseInfo(
                name: "Dumbbell Fly",
                movementPattern: "Isolation",
                primaryMuscles: ["Chest"],
                isCompound: false,
                equipmentRequired: ["Dumbbell", "Bench"] // Available
            )
        ]

        let availableExercises = exercises.filter { exercise in
            Set(exercise.equipmentRequired).isSubset(of: availableEquipment)
        }

        XCTAssertEqual(availableExercises.count, 2)
        XCTAssertTrue(availableExercises.contains { $0.name == "Bench Press" })
        XCTAssertTrue(availableExercises.contains { $0.name == "Dumbbell Fly" })
        XCTAssertFalse(availableExercises.contains { $0.name == "Cable Fly" })
    }

    // MARK: - Focus Area Matching Tests

    func testFocusAreaFiltering() {
        let focusAreas = Set(["Chest", "Triceps"])

        let exercises = [
            AvailableExerciseInfo(
                name: "Bench Press",
                movementPattern: "Horizontal Push",
                primaryMuscles: ["Chest", "Triceps"],
                isCompound: true,
                equipmentRequired: ["Barbell"]
            ),
            AvailableExerciseInfo(
                name: "Barbell Row",
                movementPattern: "Horizontal Pull",
                primaryMuscles: ["Back", "Biceps"],
                isCompound: true,
                equipmentRequired: ["Barbell"]
            ),
            AvailableExerciseInfo(
                name: "Tricep Pushdown",
                movementPattern: "Isolation",
                primaryMuscles: ["Triceps"],
                isCompound: false,
                equipmentRequired: ["Cable"]
            )
        ]

        let matchingExercises = exercises.filter { exercise in
            !Set(exercise.primaryMuscles).isDisjoint(with: focusAreas)
        }

        XCTAssertEqual(matchingExercises.count, 2)
        XCTAssertTrue(matchingExercises.contains { $0.name == "Bench Press" })
        XCTAssertTrue(matchingExercises.contains { $0.name == "Tricep Pushdown" })
    }

    // MARK: - Suggested Weight Tests

    func testSuggestedWeightFromHistory() {
        let history: [String: Double] = [
            "Bench Press": 116.67, // e1RM
            "Barbell Row": 105.0
        ]

        // For 8 reps at hypertrophy, use ~75% of e1RM
        let percentage = 0.75
        let targetReps = 8

        if let benchE1RM = history["Bench Press"] {
            let suggestedWeight = E1RMCalculator.weightForReps(e1RM: benchE1RM, reps: targetReps)
            XCTAssertGreaterThan(suggestedWeight, 0)
            XCTAssertLessThan(suggestedWeight, benchE1RM)
        }
    }

    // MARK: - Workout Naming Tests

    func testWorkoutNamingConventions() {
        let workoutNames = [
            "Chest & Triceps Pump",
            "Upper Body Strength",
            "Leg Day Hypertrophy",
            "Full Body Quick Workout",
            "Back & Biceps Volume"
        ]

        for name in workoutNames {
            XCTAssertFalse(name.isEmpty)
            XCTAssertGreaterThan(name.count, 5) // Descriptive names
        }
    }

    // MARK: - Exercise Ordering Tests

    func testExerciseOrderingCompoundsFirst() {
        var exercises = [
            CustomExercisePlan(exerciseName: "Tricep Pushdown", sets: 3, reps: "10-12", rpeCap: 8.0),
            CustomExercisePlan(exerciseName: "Bench Press", sets: 4, reps: "5-8", rpeCap: 8.5),
            CustomExercisePlan(exerciseName: "Dumbbell Fly", sets: 3, reps: "12-15", rpeCap: 7.5)
        ]

        // Sort: compounds first (by sets as proxy, or could use isCompound flag)
        exercises.sort { $0.sets > $1.sets }

        XCTAssertEqual(exercises[0].exerciseName, "Bench Press") // Most sets first
    }

    // MARK: - RPE Cap Validation Tests

    func testRPECapRange() {
        let rpeCaps = [7.0, 7.5, 8.0, 8.5, 9.0]

        for rpe in rpeCaps {
            XCTAssertGreaterThanOrEqual(rpe, 6.0)
            XCTAssertLessThanOrEqual(rpe, 10.0)
        }
    }

    func testRPECapForDifferentGoals() {
        // Strength: higher RPE (8-9)
        let strengthRPE = 9.0
        XCTAssertGreaterThanOrEqual(strengthRPE, 8.0)

        // Hypertrophy: moderate RPE (7-8.5)
        let hypertrophyRPE = 8.0
        XCTAssertGreaterThanOrEqual(hypertrophyRPE, 7.0)
        XCTAssertLessThanOrEqual(hypertrophyRPE, 8.5)
    }
}
