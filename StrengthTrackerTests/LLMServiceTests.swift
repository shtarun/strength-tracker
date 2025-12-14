import XCTest
@testable import StrengthTracker

final class LLMServiceTests: XCTestCase {
    
    var service: LLMService!
    
    @MainActor
    override func setUp() {
        super.setUp()
        service = LLMService.shared
    }
    
    // MARK: - Context Building Tests
    
    func testCoachContext_Codable() {
        let context = CoachContext(
            userGoal: "Strength",
            currentTemplate: TemplateContext(
                name: "Upper A",
                exercises: [
                    TemplateExerciseContext(
                        name: "Bench Press",
                        prescription: PrescriptionContext(
                            progressionType: "Top Set + Backoffs",
                            topSetRepsRange: "4-6",
                            topSetRPECap: 8.0,
                            backoffSets: 3,
                            backoffRepsRange: "6-10",
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
            equipmentAvailable: ["Barbell", "Dumbbell", "Bench", "Rack"],
            painFlags: []
        )
        
        // Test encoding
        let encoded = try? JSONEncoder().encode(context)
        XCTAssertNotNil(encoded)
        
        // Test decoding
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(CoachContext.self, from: data)
            XCTAssertNotNil(decoded)
            XCTAssertEqual(decoded?.userGoal, "Strength")
            XCTAssertEqual(decoded?.currentTemplate.name, "Upper A")
        }
    }
    
    func testTemplateContext_Codable() {
        let template = TemplateContext(
            name: "Lower A",
            exercises: [
                TemplateExerciseContext(
                    name: "Squat",
                    prescription: PrescriptionContext(
                        progressionType: "Top Set + Backoffs",
                        topSetRepsRange: "4-6",
                        topSetRPECap: 8.0,
                        backoffSets: 3,
                        backoffRepsRange: "6-8",
                        backoffLoadDropPercent: 0.10
                    ),
                    isOptional: false
                ),
                TemplateExerciseContext(
                    name: "Leg Curl",
                    prescription: PrescriptionContext(
                        progressionType: "Double Progression",
                        topSetRepsRange: "8-12",
                        topSetRPECap: 8.5,
                        backoffSets: 0,
                        backoffRepsRange: "0-0",
                        backoffLoadDropPercent: 0
                    ),
                    isOptional: true
                )
            ]
        )
        
        let encoded = try? JSONEncoder().encode(template)
        XCTAssertNotNil(encoded)
        
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(TemplateContext.self, from: data)
            XCTAssertEqual(decoded?.exercises.count, 2)
            XCTAssertEqual(decoded?.exercises.first?.name, "Squat")
            XCTAssertEqual(decoded?.exercises.last?.isOptional, true)
        }
    }
    
    func testExerciseHistoryContext_Codable() {
        let history = ExerciseHistoryContext(
            exerciseName: "Deadlift",
            lastSessions: [
                SessionHistoryContext(
                    date: "2024-01-15",
                    topSetWeight: 200,
                    topSetReps: 5,
                    topSetRPE: 8.0,
                    totalSets: 4,
                    e1RM: 233.3
                ),
                SessionHistoryContext(
                    date: "2024-01-08",
                    topSetWeight: 195,
                    topSetReps: 5,
                    topSetRPE: 8.0,
                    totalSets: 4,
                    e1RM: 227.5
                )
            ]
        )
        
        let encoded = try? JSONEncoder().encode(history)
        XCTAssertNotNil(encoded)
        
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(ExerciseHistoryContext.self, from: data)
            XCTAssertEqual(decoded?.exerciseName, "Deadlift")
            XCTAssertEqual(decoded?.lastSessions.count, 2)
            XCTAssertEqual(decoded?.lastSessions.first?.topSetWeight, 200)
        }
    }
    
    func testPainFlagContext_Codable() {
        let painFlag = PainFlagContext(
            exerciseName: "Bench Press",
            bodyPart: "Shoulder",
            severity: "Moderate"
        )
        
        let encoded = try? JSONEncoder().encode(painFlag)
        XCTAssertNotNil(encoded)
        
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(PainFlagContext.self, from: data)
            XCTAssertEqual(decoded?.exerciseName, "Bench Press")
            XCTAssertEqual(decoded?.bodyPart, "Shoulder")
            XCTAssertEqual(decoded?.severity, "Moderate")
        }
    }
    
    // MARK: - Response Types Tests
    
    func testTodayPlanResponse_Codable() {
        let response = TodayPlanResponse(
            exercises: [
                PlannedExerciseResponse(
                    exerciseName: "Bench Press",
                    warmupSets: [
                        PlannedSetResponse(weight: 20, reps: 10, rpeCap: 5, setCount: 1),
                        PlannedSetResponse(weight: 60, reps: 5, rpeCap: 6, setCount: 1)
                    ],
                    topSet: PlannedSetResponse(weight: 100, reps: 5, rpeCap: 8, setCount: 1),
                    backoffSets: [
                        PlannedSetResponse(weight: 90, reps: 8, rpeCap: 8, setCount: 3)
                    ],
                    workingSets: []
                )
            ],
            substitutions: [
                SubstitutionResponse(from: "Lat Pulldown", to: "Pull-ups", reason: "Equipment not available")
            ],
            adjustments: ["Reduced backoff sets due to low energy"],
            reasoning: ["Bench Press: Last 100kg x 5, maintaining weight"],
            estimatedDuration: 55
        )
        
        let encoded = try? JSONEncoder().encode(response)
        XCTAssertNotNil(encoded)
        
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(TodayPlanResponse.self, from: data)
            XCTAssertEqual(decoded?.exercises.count, 1)
            XCTAssertEqual(decoded?.exercises.first?.exerciseName, "Bench Press")
            XCTAssertEqual(decoded?.exercises.first?.warmupSets.count, 2)
            XCTAssertEqual(decoded?.exercises.first?.topSet?.weight, 100)
            XCTAssertEqual(decoded?.substitutions.count, 1)
            XCTAssertEqual(decoded?.estimatedDuration, 55)
        }
    }
    
    func testPlannedExerciseResponse_Structure() {
        let exercise = PlannedExerciseResponse(
            exerciseName: "Squat",
            warmupSets: [
                PlannedSetResponse(weight: 20, reps: 10, rpeCap: nil, setCount: 1),
                PlannedSetResponse(weight: 60, reps: 5, rpeCap: 5, setCount: 1),
                PlannedSetResponse(weight: 100, reps: 3, rpeCap: 6, setCount: 1)
            ],
            topSet: PlannedSetResponse(weight: 140, reps: 5, rpeCap: 8, setCount: 1),
            backoffSets: [
                PlannedSetResponse(weight: 125, reps: 8, rpeCap: 8, setCount: 3)
            ],
            workingSets: []
        )
        
        XCTAssertEqual(exercise.warmupSets.count, 3)
        XCTAssertNotNil(exercise.topSet)
        XCTAssertEqual(exercise.backoffSets.count, 1)
        XCTAssertEqual(exercise.backoffSets.first?.setCount, 3)
        XCTAssertTrue(exercise.workingSets.isEmpty)
    }
    
    func testInsightResponse_Codable() {
        let insight = InsightResponse(
            insight: "Squat e1RM improved by 3.5%",
            action: "Keep current progression, add weight next session",
            category: "progress"
        )
        
        let encoded = try? JSONEncoder().encode(insight)
        XCTAssertNotNil(encoded)
        
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(InsightResponse.self, from: data)
            XCTAssertEqual(decoded?.insight, "Squat e1RM improved by 3.5%")
            XCTAssertEqual(decoded?.action, "Keep current progression, add weight next session")
            XCTAssertEqual(decoded?.category, "progress")
        }
    }
    
    func testStallAnalysisResponse_Stalled() {
        let analysis = StallAnalysisResponse(
            isStalled: true,
            reason: "No e1RM improvement in 3 sessions",
            suggestedFix: "Take a micro-deload: reduce weight by 8%",
            fixType: "deload",
            details: "New target: 92kg"
        )
        
        XCTAssertTrue(analysis.isStalled)
        XCTAssertNotNil(analysis.reason)
        XCTAssertEqual(analysis.fixType, "deload")
        
        let encoded = try? JSONEncoder().encode(analysis)
        XCTAssertNotNil(encoded)
    }
    
    func testStallAnalysisResponse_NotStalled() {
        let analysis = StallAnalysisResponse(
            isStalled: false,
            reason: nil,
            suggestedFix: nil,
            fixType: nil,
            details: nil
        )
        
        XCTAssertFalse(analysis.isStalled)
        XCTAssertNil(analysis.reason)
        XCTAssertNil(analysis.suggestedFix)
    }
    
    // MARK: - Session Summary Tests
    
    func testSessionSummary_Codable() {
        let summary = SessionSummary(
            templateName: "Upper A",
            exercises: [
                ExerciseSummary(
                    name: "Bench Press",
                    topSet: SetSummary(weight: 100, reps: 5, rpe: 8.0, targetReps: 5),
                    backoffSets: [
                        SetSummary(weight: 90, reps: 8, rpe: 7.5, targetReps: 8),
                        SetSummary(weight: 90, reps: 8, rpe: 7.5, targetReps: 8),
                        SetSummary(weight: 90, reps: 7, rpe: 8.0, targetReps: 8)
                    ],
                    targetHit: true,
                    e1RM: 116.7,
                    previousE1RM: 114.3
                )
            ],
            readiness: ReadinessContext(energy: "OK", soreness: "None"),
            totalVolume: 3260,
            duration: 52
        )
        
        let encoded = try? JSONEncoder().encode(summary)
        XCTAssertNotNil(encoded)
        
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(SessionSummary.self, from: data)
            XCTAssertEqual(decoded?.templateName, "Upper A")
            XCTAssertEqual(decoded?.exercises.first?.name, "Bench Press")
            XCTAssertEqual(decoded?.exercises.first?.backoffSets.count, 3)
            XCTAssertEqual(decoded?.totalVolume, 3260)
        }
    }
    
    func testExerciseSummary_ProgressDetection() {
        let improved = ExerciseSummary(
            name: "Squat",
            topSet: SetSummary(weight: 142.5, reps: 5, rpe: 8.0, targetReps: 5),
            backoffSets: [],
            targetHit: true,
            e1RM: 166.25,
            previousE1RM: 160.0
        )
        
        XCTAssertTrue(improved.e1RM > (improved.previousE1RM ?? 0))
        
        let regressed = ExerciseSummary(
            name: "Deadlift",
            topSet: SetSummary(weight: 180, reps: 4, rpe: 9.0, targetReps: 5),
            backoffSets: [],
            targetHit: false,
            e1RM: 204.0,
            previousE1RM: 210.0
        )
        
        XCTAssertTrue(regressed.e1RM < (regressed.previousE1RM ?? 0))
    }
    
    // MARK: - Stall Context Tests
    
    func testStallContext_Codable() {
        let context = StallContext(
            exerciseName: "Overhead Press",
            lastSessions: [
                SessionHistoryContext(date: "2024-01-22", topSetWeight: 60, topSetReps: 5, topSetRPE: 8.5, totalSets: 4, e1RM: 70),
                SessionHistoryContext(date: "2024-01-15", topSetWeight: 60, topSetReps: 5, topSetRPE: 8.0, totalSets: 4, e1RM: 70),
                SessionHistoryContext(date: "2024-01-08", topSetWeight: 60, topSetReps: 5, topSetRPE: 8.0, totalSets: 4, e1RM: 70)
            ],
            currentPrescription: PrescriptionContext(
                progressionType: "Top Set + Backoffs",
                topSetRepsRange: "4-6",
                topSetRPECap: 8.0,
                backoffSets: 3,
                backoffRepsRange: "6-10",
                backoffLoadDropPercent: 0.10
            ),
            userGoal: "Strength"
        )
        
        let encoded = try? JSONEncoder().encode(context)
        XCTAssertNotNil(encoded)
        
        if let data = encoded {
            let decoded = try? JSONDecoder().decode(StallContext.self, from: data)
            XCTAssertEqual(decoded?.exerciseName, "Overhead Press")
            XCTAssertEqual(decoded?.lastSessions.count, 3)
            XCTAssertEqual(decoded?.userGoal, "Strength")
        }
    }
    
    // MARK: - JSON Parsing Edge Cases
    
    func testPlannedSetResponse_OptionalRPE() {
        // Test with RPE
        let withRPE = PlannedSetResponse(weight: 100, reps: 5, rpeCap: 8.0, setCount: 1)
        XCTAssertEqual(withRPE.rpeCap, 8.0)
        
        // Test without RPE
        let withoutRPE = PlannedSetResponse(weight: 20, reps: 10, rpeCap: nil, setCount: 1)
        XCTAssertNil(withoutRPE.rpeCap)
        
        // Both should encode/decode correctly
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        if let encodedWithRPE = try? encoder.encode(withRPE),
           let decodedWithRPE = try? decoder.decode(PlannedSetResponse.self, from: encodedWithRPE) {
            XCTAssertEqual(decodedWithRPE.rpeCap, 8.0)
        }
        
        if let encodedWithoutRPE = try? encoder.encode(withoutRPE),
           let decodedWithoutRPE = try? decoder.decode(PlannedSetResponse.self, from: encodedWithoutRPE) {
            XCTAssertNil(decodedWithoutRPE.rpeCap)
        }
    }
    
    func testExerciseHistoryContext_EmptySessions() {
        let history = ExerciseHistoryContext(
            exerciseName: "New Exercise",
            lastSessions: []
        )
        
        XCTAssertTrue(history.lastSessions.isEmpty)
        
        let encoded = try? JSONEncoder().encode(history)
        XCTAssertNotNil(encoded)
    }
    
    func testReadinessContext_AllCombinations() {
        let combinations = [
            ("Low", "None"),
            ("Low", "Mild"),
            ("Low", "High"),
            ("OK", "None"),
            ("OK", "Mild"),
            ("OK", "High"),
            ("High", "None"),
            ("High", "Mild"),
            ("High", "High")
        ]
        
        for (energy, soreness) in combinations {
            let context = ReadinessContext(energy: energy, soreness: soreness)
            
            let encoded = try? JSONEncoder().encode(context)
            XCTAssertNotNil(encoded, "Failed to encode \(energy)/\(soreness)")
            
            if let data = encoded {
                let decoded = try? JSONDecoder().decode(ReadinessContext.self, from: data)
                XCTAssertEqual(decoded?.energy, energy)
                XCTAssertEqual(decoded?.soreness, soreness)
            }
        }
    }
}
