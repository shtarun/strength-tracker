import XCTest
@testable import StrengthTracker

final class OfflineProgressionEngineTests: XCTestCase {
    
    var engine: OfflineProgressionEngine!
    
    override func setUp() {
        super.setUp()
        engine = OfflineProgressionEngine()
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func makeContext(
        energy: String = "OK",
        soreness: String = "None",
        timeAvailable: Int = 60,
        exercises: [TemplateExerciseContext] = [],
        history: [ExerciseHistoryContext] = []
    ) -> CoachContext {
        return CoachContext(
            userGoal: "Strength",
            currentTemplate: TemplateContext(
                name: "Test Template",
                exercises: exercises
            ),
            location: "Gym",
            readiness: ReadinessContext(energy: energy, soreness: soreness),
            timeAvailable: timeAvailable,
            recentHistory: history,
            equipmentAvailable: ["Barbell", "Dumbbell", "Bench", "Rack"],
            painFlags: []
        )
    }
    
    private func makePrescription(
        progressionType: String = "Top Set + Backoffs",
        topSetRepsRange: String = "4-6",
        topSetRPECap: Double = 8.0,
        backoffSets: Int = 3,
        backoffRepsRange: String = "6-10",
        backoffLoadDropPercent: Double = 0.10
    ) -> PrescriptionContext {
        return PrescriptionContext(
            progressionType: progressionType,
            topSetRepsRange: topSetRepsRange,
            topSetRPECap: topSetRPECap,
            backoffSets: backoffSets,
            backoffRepsRange: backoffRepsRange,
            backoffLoadDropPercent: backoffLoadDropPercent
        )
    }
    
    private func makeHistory(
        exerciseName: String,
        sessions: [(weight: Double, reps: Int, rpe: Double?)]
    ) -> ExerciseHistoryContext {
        return ExerciseHistoryContext(
            exerciseName: exerciseName,
            lastSessions: sessions.enumerated().map { index, session in
                SessionHistoryContext(
                    date: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double(index) * 7 * 24 * 60 * 60)),
                    topSetWeight: session.weight,
                    topSetReps: session.reps,
                    topSetRPE: session.rpe,
                    totalSets: 4,
                    e1RM: E1RMCalculator.calculate(weight: session.weight, reps: session.reps)
                )
            }
        )
    }
    
    // MARK: - Plan Generation Tests
    
    func testGeneratePlan_EmptyTemplate_ReturnsEmptyExercises() async {
        let context = makeContext(exercises: [])
        
        let plan = await engine.generatePlan(context: context)
        
        XCTAssertTrue(plan.exercises.isEmpty)
        XCTAssertEqual(plan.estimatedDuration, 0)
    }
    
    func testGeneratePlan_SingleExercise_NoHistory() async {
        let exercise = TemplateExerciseContext(
            name: "Bench Press",
            prescription: makePrescription(),
            isOptional: false
        )
        let context = makeContext(exercises: [exercise])
        
        let plan = await engine.generatePlan(context: context)
        
        XCTAssertEqual(plan.exercises.count, 1)
        XCTAssertEqual(plan.exercises.first?.exerciseName, "Bench Press")
        // Should have default starting weight
        XCTAssertEqual(plan.exercises.first?.topSet?.weight, 20.0)
    }
    
    func testGeneratePlan_WithHistory_MaintainsWeight() async {
        let exercise = TemplateExerciseContext(
            name: "Squat",
            prescription: makePrescription(),
            isOptional: false
        )
        let history = makeHistory(
            exerciseName: "Squat",
            sessions: [(weight: 100.0, reps: 4, rpe: 8.0)]
        )
        let context = makeContext(exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Should try to add a rep at same weight (didn't hit max reps)
        XCTAssertEqual(plan.exercises.first?.topSet?.weight, 100.0)
        XCTAssertEqual(plan.exercises.first?.topSet?.reps, 5)
    }
    
    func testGeneratePlan_HitMaxReps_IncreasesWeight() async {
        let exercise = TemplateExerciseContext(
            name: "Bench Press",
            prescription: makePrescription(topSetRepsRange: "4-6", topSetRPECap: 8.0),
            isOptional: false
        )
        let history = makeHistory(
            exerciseName: "Bench Press",
            sessions: [(weight: 100.0, reps: 6, rpe: 8.0)] // Hit 6 reps at RPE 8
        )
        let context = makeContext(exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Should increase weight and reset to min reps
        XCTAssertEqual(plan.exercises.first?.topSet?.weight, 102.5)
        XCTAssertEqual(plan.exercises.first?.topSet?.reps, 4)
    }
    
    func testGeneratePlan_MissedReps_KeepsWeight() async {
        let exercise = TemplateExerciseContext(
            name: "Deadlift",
            prescription: makePrescription(topSetRepsRange: "4-6"),
            isOptional: false
        )
        let history = makeHistory(
            exerciseName: "Deadlift",
            sessions: [(weight: 180.0, reps: 3, rpe: 9.0)] // Missed target reps
        )
        let context = makeContext(exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Should keep weight, target min reps
        XCTAssertEqual(plan.exercises.first?.topSet?.weight, 180.0)
        XCTAssertEqual(plan.exercises.first?.topSet?.reps, 4)
    }
    
    // MARK: - Readiness Adjustment Tests
    
    func testGeneratePlan_LowEnergy_ReducesRPECap() async {
        let exercise = TemplateExerciseContext(
            name: "Squat",
            prescription: makePrescription(topSetRPECap: 8.0),
            isOptional: false
        )
        let history = makeHistory(exerciseName: "Squat", sessions: [(weight: 140.0, reps: 5, rpe: 8.0)])
        let context = makeContext(energy: "Low", exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // RPE cap should be reduced
        XCTAssertEqual(plan.exercises.first?.topSet?.rpeCap, 7.5)
        XCTAssertTrue(plan.adjustments.contains { $0.contains("Reduced intensity") })
    }
    
    func testGeneratePlan_HighSoreness_ReducesVolume() async {
        let exercise = TemplateExerciseContext(
            name: "Bench Press",
            prescription: makePrescription(backoffSets: 3),
            isOptional: false
        )
        let history = makeHistory(exerciseName: "Bench Press", sessions: [(weight: 100.0, reps: 5, rpe: 8.0)])
        let context = makeContext(soreness: "High", exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Backoff sets should be reduced
        if let backoffSet = plan.exercises.first?.backoffSets.first {
            XCTAssertEqual(backoffSet.setCount, 2) // Reduced from 3
        }
    }
    
    func testGeneratePlan_LowEnergy_ReducesWeight() async {
        let exercise = TemplateExerciseContext(
            name: "Squat",
            prescription: makePrescription(),
            isOptional: false
        )
        let history = makeHistory(
            exerciseName: "Squat",
            sessions: [(weight: 140.0, reps: 3, rpe: 9.5)] // Struggling + low energy
        )
        let context = makeContext(energy: "Low", exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Should reduce weight by ~5%
        XCTAssertLessThan(plan.exercises.first?.topSet?.weight ?? 0, 140.0)
    }
    
    func testGeneratePlan_HighEnergy_IncreasesRPECap() async {
        let exercise = TemplateExerciseContext(
            name: "Deadlift",
            prescription: makePrescription(topSetRPECap: 8.0),
            isOptional: false
        )
        let history = makeHistory(exerciseName: "Deadlift", sessions: [(weight: 200.0, reps: 5, rpe: 7.5)])
        let context = makeContext(energy: "High", soreness: "None", exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // RPE cap should be slightly higher
        XCTAssertEqual(plan.exercises.first?.topSet?.rpeCap, 8.5)
    }
    
    // MARK: - Optional Exercise Tests
    
    func testGeneratePlan_OptionalExercise_TimeConstrained_Skips() async {
        let mainExercise = TemplateExerciseContext(
            name: "Squat",
            prescription: makePrescription(),
            isOptional: false
        )
        let optionalExercise = TemplateExerciseContext(
            name: "Leg Curl",
            prescription: makePrescription(),
            isOptional: true
        )
        let context = makeContext(
            timeAvailable: 30, // Very limited time
            exercises: [mainExercise, optionalExercise]
        )
        
        let plan = await engine.generatePlan(context: context)
        
        // Optional exercise should be skipped
        XCTAssertEqual(plan.exercises.count, 1)
        XCTAssertEqual(plan.exercises.first?.exerciseName, "Squat")
        XCTAssertTrue(plan.reasoning.contains { $0.contains("Skipped optional") })
    }
    
    func testGeneratePlan_OptionalExercise_EnoughTime_Includes() async {
        let mainExercise = TemplateExerciseContext(
            name: "Squat",
            prescription: makePrescription(),
            isOptional: false
        )
        let optionalExercise = TemplateExerciseContext(
            name: "Leg Curl",
            prescription: makePrescription(),
            isOptional: true
        )
        let context = makeContext(
            timeAvailable: 60,
            exercises: [mainExercise, optionalExercise]
        )
        
        let plan = await engine.generatePlan(context: context)
        
        // Both exercises should be included
        XCTAssertEqual(plan.exercises.count, 2)
    }
    
    // MARK: - Warmup Generation Tests
    
    func testGeneratePlan_GeneratesWarmups() async {
        let exercise = TemplateExerciseContext(
            name: "Squat",
            prescription: makePrescription(),
            isOptional: false
        )
        let history = makeHistory(exerciseName: "Squat", sessions: [(weight: 140.0, reps: 5, rpe: 8.0)])
        let context = makeContext(exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Should have warmup sets
        XCTAssertFalse(plan.exercises.first?.warmupSets.isEmpty ?? true)
    }
    
    func testGeneratePlan_WarmupProgression() async {
        let exercise = TemplateExerciseContext(
            name: "Bench Press",
            prescription: makePrescription(),
            isOptional: false
        )
        let history = makeHistory(exerciseName: "Bench Press", sessions: [(weight: 100.0, reps: 5, rpe: 8.0)])
        let context = makeContext(exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        guard let warmups = plan.exercises.first?.warmupSets, warmups.count >= 2 else {
            XCTFail("Expected at least 2 warmup sets")
            return
        }
        
        // Warmups should be in ascending order
        for i in 1..<warmups.count {
            XCTAssertGreaterThanOrEqual(warmups[i].weight, warmups[i-1].weight)
        }
    }
    
    func testGeneratePlan_LightWeight_MinimalWarmups() async {
        let exercise = TemplateExerciseContext(
            name: "Tricep Pushdown",
            prescription: makePrescription(),
            isOptional: false
        )
        let history = makeHistory(exerciseName: "Tricep Pushdown", sessions: [(weight: 25.0, reps: 10, rpe: 8.0)])
        let context = makeContext(exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Light weight should have few/no warmups
        XCTAssertTrue((plan.exercises.first?.warmupSets.count ?? 0) <= 2)
    }
    
    // MARK: - Double Progression Tests
    
    func testGeneratePlan_DoubleProgression_GeneratesWorkingSets() async {
        let exercise = TemplateExerciseContext(
            name: "Dumbbell Row",
            prescription: makePrescription(
                progressionType: "Double Progression",
                topSetRepsRange: "8-12",
                backoffSets: 0
            ),
            isOptional: false
        )
        let history = makeHistory(exerciseName: "Dumbbell Row", sessions: [(weight: 30.0, reps: 10, rpe: 8.0)])
        let context = makeContext(exercises: [exercise], history: [history])
        
        let plan = await engine.generatePlan(context: context)
        
        // Should have working sets instead of top set + backoffs
        XCTAssertFalse(plan.exercises.first?.workingSets.isEmpty ?? true)
    }
    
    // MARK: - Stall Analysis Tests
    
    func testAnalyzeStall_InsufficientData_NotStalled() async {
        let context = StallContext(
            exerciseName: "Squat",
            lastSessions: [
                SessionHistoryContext(date: "2024-01-15", topSetWeight: 140, topSetReps: 5, topSetRPE: 8, totalSets: 4, e1RM: 163),
                SessionHistoryContext(date: "2024-01-08", topSetWeight: 137.5, topSetReps: 5, topSetRPE: 8, totalSets: 4, e1RM: 160)
            ],
            currentPrescription: makePrescription(),
            userGoal: "Strength"
        )
        
        let result = await engine.analyzeStall(context: context)
        
        XCTAssertFalse(result.isStalled)
    }
    
    func testAnalyzeStall_NoProgress_DetectsStall() async {
        let context = StallContext(
            exerciseName: "Bench Press",
            lastSessions: [
                SessionHistoryContext(date: "2024-01-22", topSetWeight: 100, topSetReps: 5, topSetRPE: 8, totalSets: 4, e1RM: 116.7),
                SessionHistoryContext(date: "2024-01-15", topSetWeight: 100, topSetReps: 5, topSetRPE: 8.5, totalSets: 4, e1RM: 116.7),
                SessionHistoryContext(date: "2024-01-08", topSetWeight: 100, topSetReps: 5, topSetRPE: 8, totalSets: 4, e1RM: 116.7)
            ],
            currentPrescription: makePrescription(),
            userGoal: "Strength"
        )
        
        let result = await engine.analyzeStall(context: context)
        
        XCTAssertTrue(result.isStalled)
        XCTAssertNotNil(result.reason)
        XCTAssertNotNil(result.suggestedFix)
    }
    
    func testAnalyzeStall_HighRPE_SuggestsDeload() async {
        let context = StallContext(
            exerciseName: "Squat",
            lastSessions: [
                SessionHistoryContext(date: "2024-01-22", topSetWeight: 160, topSetReps: 4, topSetRPE: 9.5, totalSets: 4, e1RM: 181),
                SessionHistoryContext(date: "2024-01-15", topSetWeight: 160, topSetReps: 4, topSetRPE: 9.0, totalSets: 4, e1RM: 181),
                SessionHistoryContext(date: "2024-01-08", topSetWeight: 160, topSetReps: 4, topSetRPE: 9.0, totalSets: 4, e1RM: 181)
            ],
            currentPrescription: makePrescription(),
            userGoal: "Strength"
        )
        
        let result = await engine.analyzeStall(context: context)
        
        XCTAssertTrue(result.isStalled)
        XCTAssertEqual(result.fixType, "deload")
        XCTAssertTrue(result.suggestedFix?.contains("deload") ?? false)
    }
    
    func testAnalyzeStall_LowReps_SuggestsRepRangeChange() async {
        let context = StallContext(
            exerciseName: "Overhead Press",
            lastSessions: [
                SessionHistoryContext(date: "2024-01-22", topSetWeight: 60, topSetReps: 3, topSetRPE: 8, totalSets: 4, e1RM: 66),
                SessionHistoryContext(date: "2024-01-15", topSetWeight: 60, topSetReps: 3, topSetRPE: 8, totalSets: 4, e1RM: 66),
                SessionHistoryContext(date: "2024-01-08", topSetWeight: 60, topSetReps: 3, topSetRPE: 8, totalSets: 4, e1RM: 66)
            ],
            currentPrescription: makePrescription(),
            userGoal: "Strength"
        )
        
        let result = await engine.analyzeStall(context: context)
        
        XCTAssertTrue(result.isStalled)
        XCTAssertEqual(result.fixType, "rep_range")
    }
    
    func testAnalyzeStall_Progressing_NotStalled() async {
        let context = StallContext(
            exerciseName: "Deadlift",
            lastSessions: [
                SessionHistoryContext(date: "2024-01-22", topSetWeight: 200, topSetReps: 5, topSetRPE: 8, totalSets: 4, e1RM: 233),
                SessionHistoryContext(date: "2024-01-15", topSetWeight: 195, topSetReps: 5, topSetRPE: 8, totalSets: 4, e1RM: 227),
                SessionHistoryContext(date: "2024-01-08", topSetWeight: 190, topSetReps: 5, topSetRPE: 8, totalSets: 4, e1RM: 221)
            ],
            currentPrescription: makePrescription(),
            userGoal: "Strength"
        )
        
        let result = await engine.analyzeStall(context: context)
        
        XCTAssertFalse(result.isStalled)
    }
    
    // MARK: - Insight Generation Tests
    
    func testGenerateInsight_Improvement_ReturnsProgressInsight() async {
        let session = SessionSummary(
            templateName: "Upper A",
            exercises: [
                ExerciseSummary(
                    name: "Bench Press",
                    topSet: SetSummary(weight: 102.5, reps: 5, rpe: 8.0, targetReps: 5),
                    backoffSets: [],
                    targetHit: true,
                    e1RM: 119.6,
                    previousE1RM: 116.7
                )
            ],
            readiness: ReadinessContext(energy: "OK", soreness: "None"),
            totalVolume: 2500,
            duration: 55
        )
        
        let insight = await engine.generateInsight(session: session)
        
        XCTAssertEqual(insight.category, "progress")
        XCTAssertTrue(insight.insight.contains("improved"))
    }
    
    func testGenerateInsight_MissedTarget_ReturnsFatigueInsight() async {
        let session = SessionSummary(
            templateName: "Lower A",
            exercises: [
                ExerciseSummary(
                    name: "Squat",
                    topSet: SetSummary(weight: 140, reps: 4, rpe: 9.0, targetReps: 5),
                    backoffSets: [],
                    targetHit: false,
                    e1RM: 154,
                    previousE1RM: 160
                )
            ],
            readiness: ReadinessContext(energy: "Low", soreness: "Mild"),
            totalVolume: 3000,
            duration: 50
        )
        
        let insight = await engine.generateInsight(session: session)
        
        XCTAssertEqual(insight.category, "fatigue")
        XCTAssertTrue(insight.insight.contains("missed"))
    }
    
    func testGenerateInsight_SolidWorkout_ReturnsDefaultInsight() async {
        let session = SessionSummary(
            templateName: "Upper B",
            exercises: [
                ExerciseSummary(
                    name: "Overhead Press",
                    topSet: SetSummary(weight: 60, reps: 6, rpe: 8.0, targetReps: 6),
                    backoffSets: [],
                    targetHit: true,
                    e1RM: 72,
                    previousE1RM: 72 // No change
                )
            ],
            readiness: ReadinessContext(energy: "OK", soreness: "None"),
            totalVolume: 2000,
            duration: 50
        )
        
        let insight = await engine.generateInsight(session: session)
        
        XCTAssertTrue(insight.insight.contains("Solid workout"))
    }
    
    // MARK: - Duration Estimation Tests
    
    func testGeneratePlan_EstimatesDuration() async {
        let exercises = [
            TemplateExerciseContext(name: "Squat", prescription: makePrescription(backoffSets: 3), isOptional: false),
            TemplateExerciseContext(name: "RDL", prescription: makePrescription(backoffSets: 3), isOptional: false),
            TemplateExerciseContext(name: "Leg Press", prescription: makePrescription(backoffSets: 3), isOptional: false)
        ]
        
        let context = makeContext(exercises: exercises)
        
        let plan = await engine.generatePlan(context: context)
        
        // Should have reasonable duration estimate
        XCTAssertGreaterThan(plan.estimatedDuration, 0)
    }
}
