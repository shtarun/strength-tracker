import XCTest

/// Unit tests for LLM Service - Request/Response types and protocol definitions
/// Tests Codable conformance and data structure validation
final class LLMServiceTests: XCTestCase {

    // MARK: - CoachContext Tests

    func testCoachContextCodable() throws {
        let context = CoachContext(
            userGoal: "Strength",
            currentTemplate: TemplateContext(
                name: "Upper A",
                exercises: [
                    TemplateExerciseContext(
                        name: "Bench Press",
                        prescription: PrescriptionContext(
                            progressionType: "Top Set + Backoffs",
                            topSetRepsRange: "5-8",
                            topSetRPECap: 8.5,
                            backoffSets: 3,
                            backoffRepsRange: "8-10",
                            backoffLoadDropPercent: 0.10
                        ),
                        isOptional: false
                    )
                ]
            ),
            location: "Gym",
            readiness: ReadinessContext(energy: "OK", soreness: "None"),
            timeAvailable: 60,
            recentHistory: [],
            equipmentAvailable: ["Barbell", "Dumbbell"],
            painFlags: []
        )

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(CoachContext.self, from: encoded)

        XCTAssertEqual(decoded.userGoal, "Strength")
        XCTAssertEqual(decoded.currentTemplate.name, "Upper A")
        XCTAssertEqual(decoded.location, "Gym")
        XCTAssertEqual(decoded.timeAvailable, 60)
    }

    func testCoachContextWithPainFlags() throws {
        let context = CoachContext(
            userGoal: "Hypertrophy",
            currentTemplate: TemplateContext(name: "Test", exercises: []),
            location: "Home",
            readiness: ReadinessContext(energy: "High", soreness: "Mild"),
            timeAvailable: 45,
            recentHistory: [],
            equipmentAvailable: [],
            painFlags: [
                PainFlagContext(exerciseName: "Bench Press", bodyPart: "shoulders", severity: "Moderate"),
                PainFlagContext(exerciseName: nil, bodyPart: "back", severity: "Mild")
            ]
        )

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(CoachContext.self, from: encoded)

        XCTAssertEqual(decoded.painFlags.count, 2)
        XCTAssertEqual(decoded.painFlags[0].bodyPart, "shoulders")
        XCTAssertEqual(decoded.painFlags[1].severity, "Mild")
    }

    // MARK: - TemplateContext Tests

    func testTemplateContextCodable() throws {
        let template = TemplateContext(
            name: "Push Day",
            exercises: [
                TemplateExerciseContext(
                    name: "Bench Press",
                    prescription: PrescriptionContext(
                        progressionType: "Top Set + Backoffs",
                        topSetRepsRange: "5-8",
                        topSetRPECap: 8.5,
                        backoffSets: 3,
                        backoffRepsRange: "8-10",
                        backoffLoadDropPercent: 0.10
                    ),
                    isOptional: false
                ),
                TemplateExerciseContext(
                    name: "Lateral Raise",
                    prescription: PrescriptionContext(
                        progressionType: "Double Progression",
                        topSetRepsRange: "10-15",
                        topSetRPECap: 8.0,
                        backoffSets: 0,
                        backoffRepsRange: "",
                        backoffLoadDropPercent: 0
                    ),
                    isOptional: true
                )
            ]
        )

        let encoded = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(TemplateContext.self, from: encoded)

        XCTAssertEqual(decoded.name, "Push Day")
        XCTAssertEqual(decoded.exercises.count, 2)
        XCTAssertEqual(decoded.exercises[0].isOptional, false)
        XCTAssertEqual(decoded.exercises[1].isOptional, true)
    }

    // MARK: - PrescriptionContext Tests

    func testPrescriptionContextCodable() throws {
        let prescription = PrescriptionContext(
            progressionType: "Top Set + Backoffs",
            topSetRepsRange: "3-5",
            topSetRPECap: 9.0,
            backoffSets: 4,
            backoffRepsRange: "6-8",
            backoffLoadDropPercent: 0.15
        )

        let encoded = try JSONEncoder().encode(prescription)
        let decoded = try JSONDecoder().decode(PrescriptionContext.self, from: encoded)

        XCTAssertEqual(decoded.progressionType, "Top Set + Backoffs")
        XCTAssertEqual(decoded.topSetRepsRange, "3-5")
        XCTAssertEqual(decoded.topSetRPECap, 9.0)
        XCTAssertEqual(decoded.backoffSets, 4)
        XCTAssertEqual(decoded.backoffLoadDropPercent, 0.15)
    }

    // MARK: - TodayPlanResponse Tests

    func testTodayPlanResponseCodable() throws {
        let response = TodayPlanResponse(
            exercises: [
                PlannedExerciseResponse(
                    exerciseName: "Bench Press",
                    warmupSets: [
                        PlannedSetResponse(weight: 20, reps: 10, rpeCap: 5, setCount: 1),
                        PlannedSetResponse(weight: 60, reps: 5, rpeCap: 6, setCount: 1)
                    ],
                    topSet: PlannedSetResponse(weight: 100, reps: 5, rpeCap: 8.5, setCount: 1),
                    backoffSets: [PlannedSetResponse(weight: 90, reps: 8, rpeCap: 8, setCount: 3)],
                    workingSets: []
                )
            ],
            substitutions: [
                SubstitutionResponse(from: "Barbell Row", to: "Dumbbell Row", reason: "Equipment not available")
            ],
            adjustments: ["Reduced intensity due to fatigue"],
            reasoning: ["Based on previous session performance"],
            estimatedDuration: 55
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(TodayPlanResponse.self, from: encoded)

        XCTAssertEqual(decoded.exercises.count, 1)
        XCTAssertEqual(decoded.exercises[0].exerciseName, "Bench Press")
        XCTAssertEqual(decoded.exercises[0].warmupSets.count, 2)
        XCTAssertNotNil(decoded.exercises[0].topSet)
        XCTAssertEqual(decoded.substitutions.count, 1)
        XCTAssertEqual(decoded.estimatedDuration, 55)
    }

    // MARK: - PlannedSetResponse Tests

    func testPlannedSetResponseCodable() throws {
        let setResponse = PlannedSetResponse(
            weight: 100,
            reps: 5,
            rpeCap: 8.5,
            setCount: 3
        )

        let encoded = try JSONEncoder().encode(setResponse)
        let decoded = try JSONDecoder().decode(PlannedSetResponse.self, from: encoded)

        XCTAssertEqual(decoded.weight, 100)
        XCTAssertEqual(decoded.reps, 5)
        XCTAssertEqual(decoded.rpeCap, 8.5)
        XCTAssertEqual(decoded.setCount, 3)
    }

    func testPlannedSetResponseWithNilRPE() throws {
        let setResponse = PlannedSetResponse(
            weight: 60,
            reps: 10,
            rpeCap: nil,
            setCount: 1
        )

        let encoded = try JSONEncoder().encode(setResponse)
        let decoded = try JSONDecoder().decode(PlannedSetResponse.self, from: encoded)

        XCTAssertEqual(decoded.weight, 60)
        XCTAssertNil(decoded.rpeCap)
    }

    // MARK: - SessionSummary Tests

    func testSessionSummaryCodable() throws {
        let summary = SessionSummary(
            templateName: "Upper A",
            exercises: [
                ExerciseSummary(
                    name: "Bench Press",
                    topSet: SetSummary(weight: 100, reps: 5, rpe: 8.5, targetReps: 5),
                    backoffSets: [
                        SetSummary(weight: 90, reps: 8, rpe: 8.0, targetReps: 8)
                    ],
                    targetHit: true,
                    e1RM: 116.67,
                    previousE1RM: 112.5
                )
            ],
            readiness: ReadinessContext(energy: "OK", soreness: "None"),
            totalVolume: 5000,
            duration: 55
        )

        let encoded = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(SessionSummary.self, from: encoded)

        XCTAssertEqual(decoded.templateName, "Upper A")
        XCTAssertEqual(decoded.exercises.count, 1)
        XCTAssertEqual(decoded.exercises[0].targetHit, true)
        XCTAssertEqual(decoded.totalVolume, 5000)
    }

    // MARK: - StallContext Tests

    func testStallContextCodable() throws {
        let context = StallContext(
            exerciseName: "Bench Press",
            lastSessions: [
                SessionHistoryContext(
                    date: "2025-01-15",
                    topSetWeight: 100,
                    topSetReps: 5,
                    topSetRPE: 9.0,
                    totalSets: 12,
                    e1RM: 116.67
                ),
                SessionHistoryContext(
                    date: "2025-01-12",
                    topSetWeight: 100,
                    topSetReps: 5,
                    topSetRPE: 8.5,
                    totalSets: 12,
                    e1RM: 116.67
                )
            ],
            currentPrescription: PrescriptionContext(
                progressionType: "Top Set + Backoffs",
                topSetRepsRange: "5-8",
                topSetRPECap: 8.5,
                backoffSets: 3,
                backoffRepsRange: "8-10",
                backoffLoadDropPercent: 0.10
            ),
            userGoal: "Strength"
        )

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(StallContext.self, from: encoded)

        XCTAssertEqual(decoded.exerciseName, "Bench Press")
        XCTAssertEqual(decoded.lastSessions.count, 2)
        XCTAssertEqual(decoded.userGoal, "Strength")
    }

    // MARK: - WeeklyReviewContext Tests

    func testWeeklyReviewContextCodable() throws {
        let context = WeeklyReviewContext(
            workoutCount: 4,
            totalVolume: 25000,
            averageDuration: 58,
            exerciseHighlights: [
                WeeklyExerciseHighlight(
                    exerciseName: "Bench Press",
                    sessions: 2,
                    bestE1RM: 120,
                    previousBestE1RM: 116,
                    totalVolume: 5000
                )
            ],
            userGoal: "Strength"
        )

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(WeeklyReviewContext.self, from: encoded)

        XCTAssertEqual(decoded.workoutCount, 4)
        XCTAssertEqual(decoded.exerciseHighlights.count, 1)
        XCTAssertEqual(decoded.exerciseHighlights[0].bestE1RM, 120)
    }

    // MARK: - CustomWorkoutRequest Tests

    func testCustomWorkoutRequestCodable() throws {
        let request = CustomWorkoutRequest(
            userPrompt: "I want a quick upper body pump workout",
            availableExercises: [
                AvailableExerciseInfo(
                    name: "Bench Press",
                    movementPattern: "Horizontal Push",
                    primaryMuscles: ["Chest", "Triceps"],
                    isCompound: true,
                    equipmentRequired: ["Barbell", "Bench"]
                )
            ],
            equipmentAvailable: ["Barbell", "Dumbbell", "Bench"],
            userGoal: "Hypertrophy",
            location: "Gym",
            timeAvailable: 45,
            recentExerciseHistory: ["Bench Press": 116.67]
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(CustomWorkoutRequest.self, from: encoded)

        XCTAssertEqual(decoded.userPrompt, "I want a quick upper body pump workout")
        XCTAssertEqual(decoded.timeAvailable, 45)
        XCTAssertEqual(decoded.recentExerciseHistory["Bench Press"], 116.67)
    }

    // MARK: - CustomWorkoutResponse Tests

    func testCustomWorkoutResponseCodable() throws {
        let response = CustomWorkoutResponse(
            workoutName: "Upper Body Pump",
            exercises: [
                CustomExercisePlan(
                    exerciseName: "Bench Press",
                    sets: 4,
                    reps: "8-10",
                    rpeCap: 8.0,
                    notes: "Focus on squeeze at top",
                    suggestedWeight: 80
                )
            ],
            reasoning: "Selected compound movements for hypertrophy",
            estimatedDuration: 40,
            focusAreas: ["Chest", "Shoulders", "Triceps"]
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(CustomWorkoutResponse.self, from: encoded)

        XCTAssertEqual(decoded.workoutName, "Upper Body Pump")
        XCTAssertEqual(decoded.exercises.count, 1)
        XCTAssertEqual(decoded.focusAreas.count, 3)
    }

    // MARK: - CustomExercisePlan Tests

    func testCustomExercisePlanRepsRange() {
        let plan = CustomExercisePlan(
            exerciseName: "Bench Press",
            sets: 4,
            reps: "8-10",
            rpeCap: 8.0
        )

        XCTAssertEqual(plan.repsMin, 8)
        XCTAssertEqual(plan.repsMax, 10)
    }

    func testCustomExercisePlanSingleReps() {
        let plan = CustomExercisePlan(
            exerciseName: "Deadlift",
            sets: 5,
            reps: "5",
            rpeCap: 9.0
        )

        XCTAssertEqual(plan.repsMin, 5)
        XCTAssertEqual(plan.repsMax, 5)
    }

    // MARK: - GeneratePlanRequest Tests

    func testGeneratePlanRequestCodable() throws {
        let request = GeneratePlanRequest(
            goal: .strength,
            durationWeeks: 8,
            daysPerWeek: 4,
            split: .upperLower,
            equipment: [.barbell, .dumbbell, .bench, .rack],
            includeDeloads: true,
            focusAreas: [.chest, .quads]
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GeneratePlanRequest.self, from: encoded)

        XCTAssertEqual(decoded.goal, .strength)
        XCTAssertEqual(decoded.durationWeeks, 8)
        XCTAssertEqual(decoded.split, .upperLower)
        XCTAssertTrue(decoded.includeDeloads)
        XCTAssertEqual(decoded.focusAreas?.count, 2)
    }

    // MARK: - GeneratedPlanResponse Tests

    func testGeneratedPlanResponseCodable() throws {
        let response = GeneratedPlanResponse(
            planName: "8 Week Strength Builder",
            description: "Progressive overload focused strength program",
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
                        )
                    ],
                    weekNotes: "Focus on form and building base"
                )
            ],
            coachingNotes: "Progress weight when hitting top of rep range"
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(GeneratedPlanResponse.self, from: encoded)

        XCTAssertEqual(decoded.planName, "8 Week Strength Builder")
        XCTAssertEqual(decoded.weeks.count, 1)
        XCTAssertEqual(decoded.weeks[0].workouts[0].exercises[0].exerciseName, "Bench Press")
    }

    // MARK: - LLM Error Tests

    func testLLMErrorNoProvider() {
        let error = LLMError.noProvider("No API key configured")
        if case .noProvider(let message) = error {
            XCTAssertEqual(message, "No API key configured")
        } else {
            XCTFail("Should be noProvider error")
        }
    }
}
