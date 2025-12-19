import XCTest

/// Unit tests for core model types and enums
/// Tests Codable conformance, computed properties, and enum behaviors
final class ModelTests: XCTestCase {

    // MARK: - Readiness Tests

    func testReadinessDefault() {
        let readiness = Readiness.default
        XCTAssertEqual(readiness.energy, .ok)
        XCTAssertEqual(readiness.soreness, .none)
        XCTAssertEqual(readiness.timeAvailable, 60)
    }

    func testReadinessIsDefault() {
        let defaultReadiness = Readiness.default
        XCTAssertTrue(defaultReadiness.isDefault)

        let customReadiness = Readiness(energy: .high, soreness: .none, timeAvailable: 60)
        XCTAssertFalse(customReadiness.isDefault)
    }

    func testReadinessShouldReduceIntensity() {
        // Low energy should reduce intensity
        let lowEnergy = Readiness(energy: .low, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(lowEnergy.shouldReduceIntensity)

        // High soreness should reduce intensity
        let highSoreness = Readiness(energy: .ok, soreness: .high, timeAvailable: 60)
        XCTAssertTrue(highSoreness.shouldReduceIntensity)

        // Both should reduce intensity
        let both = Readiness(energy: .low, soreness: .high, timeAvailable: 60)
        XCTAssertTrue(both.shouldReduceIntensity)

        // Normal should not reduce
        let normal = Readiness(energy: .ok, soreness: .none, timeAvailable: 60)
        XCTAssertFalse(normal.shouldReduceIntensity)
    }

    func testReadinessShouldIncreaseIntensity() {
        // High energy + no soreness should increase
        let optimal = Readiness(energy: .high, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(optimal.shouldIncreaseIntensity)

        // High energy + some soreness should not increase
        let withSoreness = Readiness(energy: .high, soreness: .mild, timeAvailable: 60)
        XCTAssertFalse(withSoreness.shouldIncreaseIntensity)

        // OK energy should not increase
        let okEnergy = Readiness(energy: .ok, soreness: .none, timeAvailable: 60)
        XCTAssertFalse(okEnergy.shouldIncreaseIntensity)
    }

    func testReadinessCodable() throws {
        let readiness = Readiness(energy: .high, soreness: .mild, timeAvailable: 45)
        let encoded = try JSONEncoder().encode(readiness)
        let decoded = try JSONDecoder().decode(Readiness.self, from: encoded)

        XCTAssertEqual(decoded.energy, .high)
        XCTAssertEqual(decoded.soreness, .mild)
        XCTAssertEqual(decoded.timeAvailable, 45)
    }

    func testReadinessEquatable() {
        let r1 = Readiness(energy: .ok, soreness: .none, timeAvailable: 60)
        let r2 = Readiness(energy: .ok, soreness: .none, timeAvailable: 60)
        let r3 = Readiness(energy: .high, soreness: .none, timeAvailable: 60)

        XCTAssertEqual(r1, r2)
        XCTAssertNotEqual(r1, r3)
    }

    // MARK: - EnergyLevel Tests

    func testEnergyLevelCases() {
        XCTAssertEqual(EnergyLevel.allCases.count, 3)
        XCTAssertTrue(EnergyLevel.allCases.contains(.low))
        XCTAssertTrue(EnergyLevel.allCases.contains(.ok))
        XCTAssertTrue(EnergyLevel.allCases.contains(.high))
    }

    func testEnergyLevelRawValues() {
        XCTAssertEqual(EnergyLevel.low.rawValue, "Low")
        XCTAssertEqual(EnergyLevel.ok.rawValue, "OK")
        XCTAssertEqual(EnergyLevel.high.rawValue, "High")
    }

    func testEnergyLevelIdentifiable() {
        XCTAssertEqual(EnergyLevel.low.id, "Low")
    }

    func testEnergyLevelCodable() throws {
        let level = EnergyLevel.high
        let encoded = try JSONEncoder().encode(level)
        let decoded = try JSONDecoder().decode(EnergyLevel.self, from: encoded)
        XCTAssertEqual(decoded, level)
    }

    // MARK: - SorenessLevel Tests

    func testSorenessLevelCases() {
        XCTAssertEqual(SorenessLevel.allCases.count, 3)
        XCTAssertTrue(SorenessLevel.allCases.contains(.none))
        XCTAssertTrue(SorenessLevel.allCases.contains(.mild))
        XCTAssertTrue(SorenessLevel.allCases.contains(.high))
    }

    func testSorenessLevelRawValues() {
        XCTAssertEqual(SorenessLevel.none.rawValue, "None")
        XCTAssertEqual(SorenessLevel.mild.rawValue, "Mild")
        XCTAssertEqual(SorenessLevel.high.rawValue, "High")
    }

    // MARK: - PainSeverity Tests

    func testPainSeverityCases() {
        XCTAssertEqual(PainSeverity.allCases.count, 3)
        XCTAssertTrue(PainSeverity.allCases.contains(.mild))
        XCTAssertTrue(PainSeverity.allCases.contains(.moderate))
        XCTAssertTrue(PainSeverity.allCases.contains(.severe))
    }

    // MARK: - Goal Tests

    func testGoalCases() {
        XCTAssertEqual(Goal.allCases.count, 3)
        XCTAssertTrue(Goal.allCases.contains(.strength))
        XCTAssertTrue(Goal.allCases.contains(.hypertrophy))
        XCTAssertTrue(Goal.allCases.contains(.both))
    }

    func testGoalRawValues() {
        XCTAssertEqual(Goal.strength.rawValue, "Strength")
        XCTAssertEqual(Goal.hypertrophy.rawValue, "Hypertrophy")
        XCTAssertEqual(Goal.both.rawValue, "Both")
    }

    func testGoalDescriptions() {
        XCTAssertTrue(Goal.strength.description.contains("heavier"))
        XCTAssertTrue(Goal.hypertrophy.description.contains("muscle"))
        XCTAssertTrue(Goal.both.description.contains("Balanced"))
    }

    func testGoalCodable() throws {
        for goal in Goal.allCases {
            let encoded = try JSONEncoder().encode(goal)
            let decoded = try JSONDecoder().decode(Goal.self, from: encoded)
            XCTAssertEqual(decoded, goal)
        }
    }

    // MARK: - SetType Tests

    func testSetTypeCases() {
        XCTAssertEqual(SetType.allCases.count, 4)
        XCTAssertTrue(SetType.allCases.contains(.warmup))
        XCTAssertTrue(SetType.allCases.contains(.topSet))
        XCTAssertTrue(SetType.allCases.contains(.backoff))
        XCTAssertTrue(SetType.allCases.contains(.working))
    }

    func testSetTypeRawValues() {
        XCTAssertEqual(SetType.warmup.rawValue, "Warmup")
        XCTAssertEqual(SetType.topSet.rawValue, "Top Set")
        XCTAssertEqual(SetType.backoff.rawValue, "Backoff")
        XCTAssertEqual(SetType.working.rawValue, "Working")
    }

    func testSetTypeShortLabels() {
        XCTAssertEqual(SetType.warmup.shortLabel, "W")
        XCTAssertEqual(SetType.topSet.shortLabel, "T")
        XCTAssertEqual(SetType.backoff.shortLabel, "B")
        XCTAssertEqual(SetType.working.shortLabel, "")
    }

    func testSetTypeColors() {
        XCTAssertEqual(SetType.warmup.color, "gray")
        XCTAssertEqual(SetType.topSet.color, "orange")
        XCTAssertEqual(SetType.backoff.color, "blue")
        XCTAssertEqual(SetType.working.color, "green")
    }

    // MARK: - Equipment Tests

    func testEquipmentCases() {
        XCTAssertGreaterThan(Equipment.allCases.count, 5)
        XCTAssertTrue(Equipment.allCases.contains(.barbell))
        XCTAssertTrue(Equipment.allCases.contains(.dumbbell))
        XCTAssertTrue(Equipment.allCases.contains(.cable))
        XCTAssertTrue(Equipment.allCases.contains(.machine))
        XCTAssertTrue(Equipment.allCases.contains(.bodyweight))
    }

    func testEquipmentRequiresGym() {
        XCTAssertTrue(Equipment.cable.requiresGym)
        XCTAssertTrue(Equipment.machine.requiresGym)
        XCTAssertFalse(Equipment.barbell.requiresGym)
        XCTAssertFalse(Equipment.dumbbell.requiresGym)
        XCTAssertFalse(Equipment.bodyweight.requiresGym)
    }

    func testEquipmentCodable() throws {
        for equipment in Equipment.allCases {
            let encoded = try JSONEncoder().encode(equipment)
            let decoded = try JSONDecoder().decode(Equipment.self, from: encoded)
            XCTAssertEqual(decoded, equipment)
        }
    }

    // MARK: - Muscle Tests

    func testMuscleCases() {
        XCTAssertGreaterThan(Muscle.allCases.count, 10)
        XCTAssertTrue(Muscle.allCases.contains(.chest))
        XCTAssertTrue(Muscle.allCases.contains(.lats))
        XCTAssertTrue(Muscle.allCases.contains(.quads))
        XCTAssertTrue(Muscle.allCases.contains(.hamstrings))
    }

    func testMuscleBodyPartMapping() {
        XCTAssertEqual(Muscle.chest.bodyPart, .chest)
        XCTAssertEqual(Muscle.lats.bodyPart, .back)
        XCTAssertEqual(Muscle.upperBack.bodyPart, .back)
        XCTAssertEqual(Muscle.frontDelt.bodyPart, .shoulders)
        XCTAssertEqual(Muscle.biceps.bodyPart, .arms)
        XCTAssertEqual(Muscle.quads.bodyPart, .legs)
        XCTAssertEqual(Muscle.core.bodyPart, .core)
    }

    // MARK: - BodyPart Tests

    func testBodyPartCases() {
        XCTAssertEqual(BodyPart.allCases.count, 6)
        XCTAssertTrue(BodyPart.allCases.contains(.chest))
        XCTAssertTrue(BodyPart.allCases.contains(.back))
        XCTAssertTrue(BodyPart.allCases.contains(.shoulders))
        XCTAssertTrue(BodyPart.allCases.contains(.arms))
        XCTAssertTrue(BodyPart.allCases.contains(.legs))
        XCTAssertTrue(BodyPart.allCases.contains(.core))
    }

    // MARK: - MovementPattern Tests

    func testMovementPatternCases() {
        XCTAssertGreaterThan(MovementPattern.allCases.count, 5)
        XCTAssertTrue(MovementPattern.allCases.contains(.horizontalPush))
        XCTAssertTrue(MovementPattern.allCases.contains(.verticalPull))
        XCTAssertTrue(MovementPattern.allCases.contains(.squat))
        XCTAssertTrue(MovementPattern.allCases.contains(.hinge))
    }

    func testMovementPatternPrimaryMuscles() {
        let horizontalPush = MovementPattern.horizontalPush.primaryMuscleGroups
        XCTAssertTrue(horizontalPush.contains(.chest))
        XCTAssertTrue(horizontalPush.contains(.triceps))

        let squat = MovementPattern.squat.primaryMuscleGroups
        XCTAssertTrue(squat.contains(.quads))
        XCTAssertTrue(squat.contains(.glutes))

        let hinge = MovementPattern.hinge.primaryMuscleGroups
        XCTAssertTrue(hinge.contains(.hamstrings))
        XCTAssertTrue(hinge.contains(.glutes))
    }

    func testMovementPatternMobilityFlag() {
        XCTAssertTrue(MovementPattern.mobility.isMobility)
        XCTAssertFalse(MovementPattern.squat.isMobility)
    }

    func testMovementPatternCardioFlag() {
        XCTAssertTrue(MovementPattern.cardio.isCardio)
        XCTAssertFalse(MovementPattern.squat.isCardio)
    }

    // MARK: - StallFix Tests

    func testStallFixCases() {
        XCTAssertEqual(StallFix.allCases.count, 4)
        XCTAssertTrue(StallFix.allCases.contains(.deload))
        XCTAssertTrue(StallFix.allCases.contains(.repRange))
        XCTAssertTrue(StallFix.allCases.contains(.variation))
        XCTAssertTrue(StallFix.allCases.contains(.weightJump))
    }

    func testStallFixRawValues() {
        XCTAssertEqual(StallFix.deload.rawValue, "deload")
        XCTAssertEqual(StallFix.repRange.rawValue, "rep_range")
        XCTAssertEqual(StallFix.variation.rawValue, "variation")
        XCTAssertEqual(StallFix.weightJump.rawValue, "weight_jump")
    }

    func testStallFixDisplayNames() {
        XCTAssertEqual(StallFix.deload.displayName, "Deload Week")
        XCTAssertEqual(StallFix.repRange.displayName, "Change Rep Range")
        XCTAssertEqual(StallFix.variation.displayName, "Switch Variation")
        XCTAssertEqual(StallFix.weightJump.displayName, "Force Weight Increase")
    }

    // MARK: - LLM Response Types Tests

    func testStallAnalysisResponseCodable() throws {
        let response = StallAnalysisResponse(
            isStalled: true,
            reason: "No progress for 3 weeks",
            suggestedFix: "Deload by 10%",
            fixType: "deload",
            details: "Reduce weight for one week"
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(StallAnalysisResponse.self, from: encoded)

        XCTAssertEqual(decoded.isStalled, true)
        XCTAssertEqual(decoded.reason, "No progress for 3 weeks")
        XCTAssertEqual(decoded.fixType, "deload")
    }

    func testInsightResponseCodable() throws {
        let response = InsightResponse(
            insight: "Great progress on bench press",
            action: "Increase weight by 2.5kg next session",
            category: "progress"
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(InsightResponse.self, from: encoded)

        XCTAssertEqual(decoded.insight, "Great progress on bench press")
        XCTAssertEqual(decoded.category, "progress")
    }

    func testPlannedSetResponseCodable() throws {
        let response = PlannedSetResponse(
            weight: 100,
            reps: 5,
            rpeCap: 8.5,
            setCount: 3
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(PlannedSetResponse.self, from: encoded)

        XCTAssertEqual(decoded.weight, 100)
        XCTAssertEqual(decoded.reps, 5)
        XCTAssertEqual(decoded.rpeCap, 8.5)
        XCTAssertEqual(decoded.setCount, 3)
    }

    func testWeeklyReviewResponseCodable() throws {
        let response = WeeklyReviewResponse(
            summary: "Good week of training",
            highlights: ["PR on squat", "Consistent training"],
            areasToImprove: ["More sleep"],
            recommendation: "Add 2.5kg to main lifts",
            consistencyScore: 8
        )

        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(WeeklyReviewResponse.self, from: encoded)

        XCTAssertEqual(decoded.summary, "Good week of training")
        XCTAssertEqual(decoded.highlights.count, 2)
        XCTAssertEqual(decoded.consistencyScore, 8)
    }

    // MARK: - Context Types Tests

    func testReadinessContextCodable() throws {
        let context = ReadinessContext(energy: "High", soreness: "None")

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(ReadinessContext.self, from: encoded)

        XCTAssertEqual(decoded.energy, "High")
        XCTAssertEqual(decoded.soreness, "None")
    }

    func testPainFlagContextCodable() throws {
        let context = PainFlagContext(
            exerciseName: "Bench Press",
            bodyPart: "shoulders",
            severity: "Mild"
        )

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(PainFlagContext.self, from: encoded)

        XCTAssertEqual(decoded.exerciseName, "Bench Press")
        XCTAssertEqual(decoded.bodyPart, "shoulders")
        XCTAssertEqual(decoded.severity, "Mild")
    }

    func testSessionHistoryContextCodable() throws {
        let context = SessionHistoryContext(
            date: "2025-01-15",
            topSetWeight: 100,
            topSetReps: 5,
            topSetRPE: 8.5,
            totalSets: 12,
            e1RM: 116.67
        )

        let encoded = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(SessionHistoryContext.self, from: encoded)

        XCTAssertEqual(decoded.topSetWeight, 100)
        XCTAssertEqual(decoded.topSetReps, 5)
        XCTAssertEqual(decoded.e1RM, 116.67)
    }
}
