import XCTest

/// Unit tests for OfflineProgressionEngine - Rule-based workout planning
/// Tests the offline fallback for LLM-based planning
final class OfflineProgressionEngineTests: XCTestCase {

    // MARK: - Test Helpers

    private let engine = OfflineProgressionEngine()

    private func createDefaultContext(
        energy: String = "OK",
        soreness: String = "None",
        timeAvailable: Int = 60,
        exercises: [TemplateExerciseContext] = [],
        recentHistory: [ExerciseHistoryContext] = [],
        painFlags: [PainFlagContext] = []
    ) -> CoachContext {
        return CoachContext(
            userGoal: "Strength",
            currentTemplate: TemplateContext(
                name: "Upper A",
                exercises: exercises.isEmpty ? [
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
                        name: "Barbell Row",
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
                ] : exercises
            ),
            location: "Gym",
            readiness: ReadinessContext(energy: energy, soreness: soreness),
            timeAvailable: timeAvailable,
            recentHistory: recentHistory,
            equipmentAvailable: ["Barbell", "Dumbbell", "Cable"],
            painFlags: painFlags
        )
    }

    private func createExerciseHistory(
        name: String,
        lastWeight: Double,
        lastReps: Int,
        lastRPE: Double? = 8.0
    ) -> ExerciseHistoryContext {
        return ExerciseHistoryContext(
            exerciseName: name,
            lastSessions: [
                SessionHistoryContext(
                    date: "2025-01-15",
                    topSetWeight: lastWeight,
                    topSetReps: lastReps,
                    topSetRPE: lastRPE,
                    totalSets: 5,
                    e1RM: E1RMCalculator.calculate(weight: lastWeight, reps: lastReps)
                )
            ]
        )
    }

    // MARK: - Basic Plan Generation Tests

    func testGeneratePlanReturnsExercises() async {
        let context = createDefaultContext()
        let result = await engine.generatePlan(context: context)

        XCTAssertGreaterThan(result.exercises.count, 0, "Plan should contain exercises")
    }

    func testGeneratePlanIncludesAllNonOptionalExercises() async {
        let context = createDefaultContext()
        let result = await engine.generatePlan(context: context)

        // Should include Bench Press and Barbell Row (non-optional)
        let exerciseNames = result.exercises.map { $0.exerciseName }
        XCTAssertTrue(exerciseNames.contains("Bench Press"))
        XCTAssertTrue(exerciseNames.contains("Barbell Row"))
    }

    func testGeneratePlanEstimatesDuration() async {
        let context = createDefaultContext()
        let result = await engine.generatePlan(context: context)

        XCTAssertGreaterThan(result.estimatedDuration, 0, "Should estimate workout duration")
    }

    // MARK: - Warmup Generation Tests

    func testWarmupsGeneratedForHeavyExercises() async {
        let context = createDefaultContext(
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let result = await engine.generatePlan(context: context)

        guard let benchPlan = result.exercises.first(where: { $0.exerciseName == "Bench Press" }) else {
            XCTFail("Bench Press should be in plan")
            return
        }

        XCTAssertGreaterThan(benchPlan.warmupSets.count, 0, "Heavy exercise should have warmups")
    }

    func testWarmupsProgressToTopSetWeight() async {
        let context = createDefaultContext(
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let result = await engine.generatePlan(context: context)

        guard let benchPlan = result.exercises.first(where: { $0.exerciseName == "Bench Press" }) else {
            XCTFail("Bench Press should be in plan")
            return
        }

        // Warmups should be sorted in ascending order
        let warmupWeights = benchPlan.warmupSets.map { $0.weight }
        XCTAssertEqual(warmupWeights, warmupWeights.sorted())

        // Last warmup should be less than top set
        if let topSet = benchPlan.topSet, let lastWarmup = warmupWeights.last {
            XCTAssertLessThan(lastWarmup, topSet.weight)
        }
    }

    // MARK: - Top Set Calculation Tests

    func testTopSetProgressionWhenAtRepCap() async {
        // Previous session: 100kg x 8 reps at RPE 8.0 (hit top of rep range)
        let context = createDefaultContext(
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 8, lastRPE: 8.0)]
        )
        let result = await engine.generatePlan(context: context)

        guard let benchPlan = result.exercises.first(where: { $0.exerciseName == "Bench Press" }),
              let topSet = benchPlan.topSet else {
            XCTFail("Bench Press should have top set")
            return
        }

        // Should increase weight since hit top of rep range
        XCTAssertGreaterThan(topSet.weight, 100, "Weight should increase after hitting rep cap")
    }

    func testTopSetMaintainsWeightWhenMissingReps() async {
        // Previous session: 100kg x 4 reps at RPE 9.0 (below target)
        let context = createDefaultContext(
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 4, lastRPE: 9.0)]
        )
        let result = await engine.generatePlan(context: context)

        guard let benchPlan = result.exercises.first(where: { $0.exerciseName == "Bench Press" }),
              let topSet = benchPlan.topSet else {
            XCTFail("Bench Press should have top set")
            return
        }

        // Should maintain weight or reduce
        XCTAssertLessThanOrEqual(topSet.weight, 100, "Weight should not increase when struggling")
    }

    func testNoHistoryStartsConservative() async {
        // No history for this exercise
        let context = createDefaultContext(recentHistory: [])
        let result = await engine.generatePlan(context: context)

        guard let benchPlan = result.exercises.first(where: { $0.exerciseName == "Bench Press" }),
              let topSet = benchPlan.topSet else {
            XCTFail("Bench Press should have top set")
            return
        }

        // Should start with conservative weight (default starting weight)
        XCTAssertEqual(topSet.weight, 20, "No history should use default starting weight")
    }

    // MARK: - Backoff Sets Tests

    func testBackoffSetsGeneratedForTopSetBackoffs() async {
        let context = createDefaultContext(
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let result = await engine.generatePlan(context: context)

        guard let benchPlan = result.exercises.first(where: { $0.exerciseName == "Bench Press" }) else {
            XCTFail("Bench Press should be in plan")
            return
        }

        XCTAssertGreaterThan(benchPlan.backoffSets.count, 0, "Should have backoff sets")
    }

    func testBackoffSetsLighterThanTopSet() async {
        let context = createDefaultContext(
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let result = await engine.generatePlan(context: context)

        guard let benchPlan = result.exercises.first(where: { $0.exerciseName == "Bench Press" }),
              let topSet = benchPlan.topSet else {
            XCTFail("Bench Press should have top set")
            return
        }

        for backoffSet in benchPlan.backoffSets {
            XCTAssertLessThan(backoffSet.weight, topSet.weight, "Backoff should be lighter than top set")
        }
    }

    // MARK: - Readiness Adjustment Tests

    func testLowEnergyReducesIntensity() async {
        let context = createDefaultContext(
            energy: "Low",
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let result = await engine.generatePlan(context: context)

        XCTAssertTrue(result.adjustments.contains { $0.lowercased().contains("reduced") },
                      "Should note reduced intensity")
    }

    func testHighSorenessReducesIntensity() async {
        let context = createDefaultContext(
            soreness: "High",
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let result = await engine.generatePlan(context: context)

        XCTAssertTrue(result.adjustments.contains { $0.lowercased().contains("reduced") },
                      "Should note reduced intensity due to soreness")
    }

    func testLowEnergyReducesBackoffSets() async {
        let normalContext = createDefaultContext(
            energy: "OK",
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let lowEnergyContext = createDefaultContext(
            energy: "Low",
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )

        let normalResult = await engine.generatePlan(context: normalContext)
        let lowEnergyResult = await engine.generatePlan(context: lowEnergyContext)

        guard let normalBench = normalResult.exercises.first(where: { $0.exerciseName == "Bench Press" }),
              let lowEnergyBench = lowEnergyResult.exercises.first(where: { $0.exerciseName == "Bench Press" }) else {
            XCTFail("Bench Press should be in both plans")
            return
        }

        let normalBackoffCount = normalBench.backoffSets.reduce(0) { $0 + $1.setCount }
        let lowEnergyBackoffCount = lowEnergyBench.backoffSets.reduce(0) { $0 + $1.setCount }

        XCTAssertLessThanOrEqual(lowEnergyBackoffCount, normalBackoffCount,
                                  "Low energy should have fewer or equal backoff sets")
    }

    func testHighEnergyCanIncreaseVolume() async {
        let normalContext = createDefaultContext(
            energy: "OK",
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )
        let highEnergyContext = createDefaultContext(
            energy: "High",
            recentHistory: [createExerciseHistory(name: "Bench Press", lastWeight: 100, lastReps: 5)]
        )

        let normalResult = await engine.generatePlan(context: normalContext)
        let highEnergyResult = await engine.generatePlan(context: highEnergyContext)

        guard let normalBench = normalResult.exercises.first(where: { $0.exerciseName == "Bench Press" }),
              let highEnergyBench = highEnergyResult.exercises.first(where: { $0.exerciseName == "Bench Press" }) else {
            XCTFail("Bench Press should be in both plans")
            return
        }

        let normalBackoffCount = normalBench.backoffSets.reduce(0) { $0 + $1.setCount }
        let highEnergyBackoffCount = highEnergyBench.backoffSets.reduce(0) { $0 + $1.setCount }

        XCTAssertGreaterThanOrEqual(highEnergyBackoffCount, normalBackoffCount,
                                     "High energy can have more backoff sets")
    }

    // MARK: - Time Constraint Tests

    func testTimeConstraintSkipsOptionalExercises() async {
        let shortTimeContext = createDefaultContext(timeAvailable: 30)
        let result = await engine.generatePlan(context: shortTimeContext)

        // Optional exercise (Lateral Raise) should be skipped
        let exerciseNames = result.exercises.map { $0.exerciseName }
        XCTAssertFalse(exerciseNames.contains("Lateral Raise"),
                       "Optional exercise should be skipped with short time")
    }

    func testAdequateTimeIncludesOptionalExercises() async {
        let normalTimeContext = createDefaultContext(timeAvailable: 60)
        let result = await engine.generatePlan(context: normalTimeContext)

        // Optional exercise should be included
        let exerciseNames = result.exercises.map { $0.exerciseName }
        XCTAssertTrue(exerciseNames.contains("Lateral Raise"),
                      "Optional exercise should be included with adequate time")
    }

    // MARK: - Pain Flag Tests

    func testPainFlagTriggersSubstitution() async {
        let context = createDefaultContext(
            painFlags: [
                PainFlagContext(exerciseName: nil, bodyPart: "shoulders", severity: "Moderate")
            ]
        )
        let result = await engine.generatePlan(context: context)

        // Bench Press targets shoulders (secondary) - might trigger substitution
        XCTAssertTrue(result.adjustments.contains { $0.lowercased().contains("pain") } ||
                      result.substitutions.count > 0 ||
                      result.reasoning.contains { $0.lowercased().contains("pain") },
                      "Pain flag should be acknowledged in plan")
    }

    func testPainFlagSubstitutionRecorded() async {
        let context = createDefaultContext(
            painFlags: [
                PainFlagContext(exerciseName: "Bench Press", bodyPart: "chest", severity: "Severe")
            ]
        )
        let result = await engine.generatePlan(context: context)

        // Check if substitution was made or pain was noted
        let hasSubstitution = result.substitutions.contains { $0.from == "Bench Press" }
        let hasPainNote = result.adjustments.contains { $0.lowercased().contains("pain") }
        let hasReasoning = result.reasoning.contains { $0.lowercased().contains("pain") || $0.lowercased().contains("substitut") }

        XCTAssertTrue(hasSubstitution || hasPainNote || hasReasoning,
                      "Severe pain should trigger substitution or note")
    }

    // MARK: - Insight Generation Tests

    func testGenerateInsightForImprovement() async {
        let session = SessionSummary(
            templateName: "Upper A",
            exercises: [
                ExerciseSummary(
                    name: "Bench Press",
                    topSet: SetSummary(weight: 102.5, reps: 5, rpe: 8.0, targetReps: 5),
                    backoffSets: [],
                    targetHit: true,
                    e1RM: 119.6,
                    previousE1RM: 116.7 // Improvement
                )
            ],
            readiness: ReadinessContext(energy: "OK", soreness: "None"),
            totalVolume: 5000,
            duration: 45
        )

        let result = await engine.generateInsight(session: session)

        XCTAssertFalse(result.insight.isEmpty, "Should generate insight")
        XCTAssertFalse(result.action.isEmpty, "Should provide action")
        XCTAssertFalse(result.category.isEmpty, "Should have category")
    }

    func testGenerateInsightForMissedTarget() async {
        let session = SessionSummary(
            templateName: "Upper A",
            exercises: [
                ExerciseSummary(
                    name: "Bench Press",
                    topSet: SetSummary(weight: 100, reps: 4, rpe: 9.0, targetReps: 5),
                    backoffSets: [],
                    targetHit: false,
                    e1RM: 113.3,
                    previousE1RM: 116.7 // Decrease
                )
            ],
            readiness: ReadinessContext(energy: "Low", soreness: "Mild"),
            totalVolume: 4000,
            duration: 40
        )

        let result = await engine.generateInsight(session: session)

        XCTAssertTrue(result.insight.lowercased().contains("missed") ||
                      result.category == "fatigue",
                      "Should note missed target")
    }

    // MARK: - Weekly Review Tests

    func testGenerateWeeklyReviewGoodWeek() async {
        let context = WeeklyReviewContext(
            workoutCount: 4,
            totalVolume: 20000,
            averageDuration: 55,
            exerciseHighlights: [
                WeeklyExerciseHighlight(
                    exerciseName: "Bench Press",
                    sessions: 2,
                    bestE1RM: 120,
                    previousBestE1RM: 116, // PR
                    totalVolume: 5000
                )
            ],
            userGoal: "Strength"
        )

        let result = await engine.generateWeeklyReview(context: context)

        XCTAssertGreaterThanOrEqual(result.consistencyScore, 7, "Good week should have high score")
        XCTAssertFalse(result.summary.isEmpty)
        XCTAssertGreaterThan(result.highlights.count, 0)
    }

    func testGenerateWeeklyReviewPoorWeek() async {
        let context = WeeklyReviewContext(
            workoutCount: 1,
            totalVolume: 5000,
            averageDuration: 30,
            exerciseHighlights: [],
            userGoal: "Strength"
        )

        let result = await engine.generateWeeklyReview(context: context)

        XCTAssertLessThanOrEqual(result.consistencyScore, 5, "Poor week should have low score")
        XCTAssertGreaterThan(result.areasToImprove.count, 0, "Should suggest improvements")
    }

    // MARK: - Double Progression Tests

    func testDoubleProgressionGeneratesWorkingSets() async {
        let doubleProgressionContext = createDefaultContext(
            exercises: [
                TemplateExerciseContext(
                    name: "Bicep Curl",
                    prescription: PrescriptionContext(
                        progressionType: "Double Progression",
                        topSetRepsRange: "10-15",
                        topSetRPECap: 8.0,
                        backoffSets: 0,
                        backoffRepsRange: "",
                        backoffLoadDropPercent: 0
                    ),
                    isOptional: false
                )
            ],
            recentHistory: [createExerciseHistory(name: "Bicep Curl", lastWeight: 15, lastReps: 12)]
        )

        let result = await engine.generatePlan(context: doubleProgressionContext)

        guard let curlPlan = result.exercises.first(where: { $0.exerciseName == "Bicep Curl" }) else {
            XCTFail("Bicep Curl should be in plan")
            return
        }

        XCTAssertGreaterThan(curlPlan.workingSets.count, 0, "Double progression should have working sets")
        XCTAssertNil(curlPlan.topSet, "Double progression should not have designated top set")
    }
}
