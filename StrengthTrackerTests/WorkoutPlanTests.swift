import XCTest

/// Unit tests for WorkoutPlan and PlanWeek models
/// Tests plan progression, week types, and periodization logic
final class WorkoutPlanTests: XCTestCase {

    // MARK: - WeekType Tests

    func testWeekTypeCases() {
        XCTAssertEqual(WeekType.allCases.count, 4)
        XCTAssertTrue(WeekType.allCases.contains(.regular))
        XCTAssertTrue(WeekType.allCases.contains(.deload))
        XCTAssertTrue(WeekType.allCases.contains(.test))
        XCTAssertTrue(WeekType.allCases.contains(.peak))
    }

    func testWeekTypeRawValues() {
        XCTAssertEqual(WeekType.regular.rawValue, "Regular")
        XCTAssertEqual(WeekType.deload.rawValue, "Deload")
        XCTAssertEqual(WeekType.test.rawValue, "Test/Max")
        XCTAssertEqual(WeekType.peak.rawValue, "Peak")
    }

    func testWeekTypeCodable() throws {
        for weekType in WeekType.allCases {
            let encoded = try JSONEncoder().encode(weekType)
            let decoded = try JSONDecoder().decode(WeekType.self, from: encoded)
            XCTAssertEqual(decoded, weekType)
        }
    }

    // MARK: - GeneratedWeek Tests

    func testGeneratedWeekCodable() throws {
        let week = GeneratedWeek(
            weekNumber: 1,
            weekType: "regular",
            workouts: [
                GeneratedWorkout(
                    dayNumber: 1,
                    name: "Upper A",
                    exercises: [
                        GeneratedExercise(
                            exerciseName: "Bench Press",
                            sets: 4,
                            repsMin: 5,
                            repsMax: 8,
                            rpe: 8.5,
                            notes: nil
                        )
                    ],
                    targetDuration: 60
                )
            ],
            weekNotes: "Focus on building base"
        )

        let encoded = try JSONEncoder().encode(week)
        let decoded = try JSONDecoder().decode(GeneratedWeek.self, from: encoded)

        XCTAssertEqual(decoded.weekNumber, 1)
        XCTAssertEqual(decoded.weekType, "regular")
        XCTAssertEqual(decoded.workouts.count, 1)
        XCTAssertEqual(decoded.weekNotes, "Focus on building base")
    }

    // MARK: - GeneratedWorkout Tests

    func testGeneratedWorkoutCodable() throws {
        let workout = GeneratedWorkout(
            dayNumber: 2,
            name: "Lower A",
            exercises: [
                GeneratedExercise(
                    exerciseName: "Barbell Squat",
                    sets: 4,
                    repsMin: 5,
                    repsMax: 8,
                    rpe: 8.5,
                    notes: "Pause at bottom"
                ),
                GeneratedExercise(
                    exerciseName: "Romanian Deadlift",
                    sets: 3,
                    repsMin: 8,
                    repsMax: 10,
                    rpe: 8.0,
                    notes: nil
                )
            ],
            targetDuration: 55
        )

        let encoded = try JSONEncoder().encode(workout)
        let decoded = try JSONDecoder().decode(GeneratedWorkout.self, from: encoded)

        XCTAssertEqual(decoded.dayNumber, 2)
        XCTAssertEqual(decoded.name, "Lower A")
        XCTAssertEqual(decoded.exercises.count, 2)
        XCTAssertEqual(decoded.targetDuration, 55)
    }

    // MARK: - GeneratedExercise Tests

    func testGeneratedExerciseCodable() throws {
        let exercise = GeneratedExercise(
            exerciseName: "Bench Press",
            sets: 4,
            repsMin: 5,
            repsMax: 8,
            rpe: 8.5,
            notes: "Control the descent"
        )

        let encoded = try JSONEncoder().encode(exercise)
        let decoded = try JSONDecoder().decode(GeneratedExercise.self, from: encoded)

        XCTAssertEqual(decoded.exerciseName, "Bench Press")
        XCTAssertEqual(decoded.sets, 4)
        XCTAssertEqual(decoded.repsMin, 5)
        XCTAssertEqual(decoded.repsMax, 8)
        XCTAssertEqual(decoded.rpe, 8.5)
        XCTAssertEqual(decoded.notes, "Control the descent")
    }

    func testGeneratedExerciseWithNilRPE() throws {
        let exercise = GeneratedExercise(
            exerciseName: "Lateral Raise",
            sets: 3,
            repsMin: 12,
            repsMax: 15,
            rpe: nil,
            notes: nil
        )

        let encoded = try JSONEncoder().encode(exercise)
        let decoded = try JSONDecoder().decode(GeneratedExercise.self, from: encoded)

        XCTAssertNil(decoded.rpe)
        XCTAssertNil(decoded.notes)
    }

    // MARK: - Full Plan Structure Tests

    func testFullPlanStructure() throws {
        let plan = GeneratedPlanResponse(
            planName: "8 Week Strength Program",
            description: "Progressive overload focused program for intermediate lifters",
            weeks: [
                GeneratedWeek(
                    weekNumber: 1,
                    weekType: "regular",
                    workouts: [
                        GeneratedWorkout(
                            dayNumber: 1,
                            name: "Upper A",
                            exercises: [
                                GeneratedExercise(
                                    exerciseName: "Bench Press",
                                    sets: 4,
                                    repsMin: 5,
                                    repsMax: 8,
                                    rpe: 8.5,
                                    notes: nil
                                )
                            ],
                            targetDuration: 60
                        ),
                        GeneratedWorkout(
                            dayNumber: 2,
                            name: "Lower A",
                            exercises: [
                                GeneratedExercise(
                                    exerciseName: "Barbell Squat",
                                    sets: 4,
                                    repsMin: 5,
                                    repsMax: 8,
                                    rpe: 8.5,
                                    notes: nil
                                )
                            ],
                            targetDuration: 60
                        )
                    ],
                    weekNotes: "Week 1: Build base"
                ),
                GeneratedWeek(
                    weekNumber: 4,
                    weekType: "deload",
                    workouts: [
                        GeneratedWorkout(
                            dayNumber: 1,
                            name: "Deload Upper",
                            exercises: [
                                GeneratedExercise(
                                    exerciseName: "Bench Press",
                                    sets: 2,
                                    repsMin: 5,
                                    repsMax: 8,
                                    rpe: 6.0,
                                    notes: "Light weight, focus on technique"
                                )
                            ],
                            targetDuration: 40
                        )
                    ],
                    weekNotes: "Deload week - recover and prepare for next block"
                )
            ],
            coachingNotes: "Increase weight when hitting top of rep range at or below target RPE"
        )

        let encoded = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(GeneratedPlanResponse.self, from: encoded)

        XCTAssertEqual(decoded.planName, "8 Week Strength Program")
        XCTAssertEqual(decoded.weeks.count, 2)
        XCTAssertEqual(decoded.weeks[0].weekType, "regular")
        XCTAssertEqual(decoded.weeks[1].weekType, "deload")
    }

    // MARK: - Split Pattern Tests

    func testUpperLowerSplitStructure() throws {
        let request = GeneratePlanRequest(
            goal: .strength,
            durationWeeks: 4,
            daysPerWeek: 4,
            split: .upperLower,
            equipment: [.barbell, .dumbbell, .bench, .rack],
            includeDeloads: false,
            focusAreas: nil
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GeneratePlanRequest.self, from: encoded)

        XCTAssertEqual(decoded.split, .upperLower)
        XCTAssertEqual(decoded.daysPerWeek, 4)
    }

    func testPPLSplitStructure() throws {
        let request = GeneratePlanRequest(
            goal: .hypertrophy,
            durationWeeks: 6,
            daysPerWeek: 6,
            split: .ppl,
            equipment: [.barbell, .dumbbell, .cable, .machine],
            includeDeloads: true,
            focusAreas: [.chest, .lats]
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GeneratePlanRequest.self, from: encoded)

        XCTAssertEqual(decoded.split, .ppl)
        XCTAssertEqual(decoded.daysPerWeek, 6)
        XCTAssertEqual(decoded.focusAreas?.count, 2)
    }

    func testFullBodySplitStructure() throws {
        let request = GeneratePlanRequest(
            goal: .both,
            durationWeeks: 8,
            daysPerWeek: 3,
            split: .fullBody,
            equipment: [.barbell, .dumbbell],
            includeDeloads: true,
            focusAreas: nil
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GeneratePlanRequest.self, from: encoded)

        XCTAssertEqual(decoded.split, .fullBody)
        XCTAssertEqual(decoded.daysPerWeek, 3)
    }

    // MARK: - Periodization Tests

    func testDeloadWeekConfiguration() {
        let deloadWeek = GeneratedWeek(
            weekNumber: 4,
            weekType: "deload",
            workouts: [],
            weekNotes: "Recovery week"
        )

        XCTAssertEqual(deloadWeek.weekType, "deload")
    }

    func testPeakWeekConfiguration() {
        let peakWeek = GeneratedWeek(
            weekNumber: 8,
            weekType: "peak",
            workouts: [],
            weekNotes: "Peak week - prepare for testing"
        )

        XCTAssertEqual(peakWeek.weekType, "peak")
    }

    func testTestWeekConfiguration() {
        let testWeek = GeneratedWeek(
            weekNumber: 9,
            weekType: "test",
            workouts: [],
            weekNotes: "Testing week - find new maxes"
        )

        XCTAssertEqual(testWeek.weekType, "test")
    }

    // MARK: - Week Modifiers Tests

    func testWeekTypeDisplayProperties() {
        // Test that week types have expected modifiers
        // These would typically be defined on the WeekType enum
        let regularWeek = WeekType.regular
        let deloadWeek = WeekType.deload
        let peakWeek = WeekType.peak

        XCTAssertEqual(regularWeek.rawValue, "Regular")
        XCTAssertEqual(deloadWeek.rawValue, "Deload")
        XCTAssertEqual(peakWeek.rawValue, "Peak")
    }

    // MARK: - Duration and Volume Tests

    func testWorkoutDurationRange() throws {
        let workout = GeneratedWorkout(
            dayNumber: 1,
            name: "Upper A",
            exercises: [],
            targetDuration: 60
        )

        XCTAssertGreaterThanOrEqual(workout.targetDuration, 0)
        XCTAssertLessThanOrEqual(workout.targetDuration, 120)
    }

    func testExerciseSetsRange() throws {
        let exercise = GeneratedExercise(
            exerciseName: "Bench Press",
            sets: 4,
            repsMin: 5,
            repsMax: 8,
            rpe: 8.5,
            notes: nil
        )

        XCTAssertGreaterThan(exercise.sets, 0)
        XCTAssertLessThanOrEqual(exercise.sets, 10)
        XCTAssertLessThanOrEqual(exercise.repsMin, exercise.repsMax)
    }

    // MARK: - Goal-Specific Configuration Tests

    func testStrengthGoalConfiguration() throws {
        let request = GeneratePlanRequest(
            goal: .strength,
            durationWeeks: 8,
            daysPerWeek: 4,
            split: .upperLower,
            equipment: [.barbell, .dumbbell],
            includeDeloads: true,
            focusAreas: nil
        )

        XCTAssertEqual(request.goal, .strength)
        // Strength programs typically have lower reps and higher intensity
    }

    func testHypertrophyGoalConfiguration() throws {
        let request = GeneratePlanRequest(
            goal: .hypertrophy,
            durationWeeks: 12,
            daysPerWeek: 5,
            split: .ppl,
            equipment: [.barbell, .dumbbell, .cable, .machine],
            includeDeloads: true,
            focusAreas: [.chest, .lats, .quads]
        )

        XCTAssertEqual(request.goal, .hypertrophy)
        // Hypertrophy programs typically have moderate reps and more volume
    }
}
