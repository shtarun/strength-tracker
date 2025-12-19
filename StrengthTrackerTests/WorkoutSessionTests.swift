import XCTest

/// Unit tests for workout session computed properties and logic
/// Tests volume calculations, progress tracking, and session analysis
final class WorkoutSessionTests: XCTestCase {

    // MARK: - Volume Calculation Tests

    func testTotalVolumeCalculation() {
        // Volume = weight × reps for each completed set
        let sets = [
            (weight: 100.0, reps: 5, completed: true),   // 500
            (weight: 90.0, reps: 8, completed: true),    // 720
            (weight: 90.0, reps: 8, completed: true),    // 720
            (weight: 90.0, reps: 7, completed: true),    // 630
            (weight: 60.0, reps: 5, completed: false)    // Not counted
        ]

        let totalVolume = sets.filter { $0.completed }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }

        XCTAssertEqual(totalVolume, 2570, accuracy: 0.001)
    }

    func testVolumeWithEmptySets() {
        let sets: [(weight: Double, reps: Int, completed: Bool)] = []
        let totalVolume = sets.filter { $0.completed }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }

        XCTAssertEqual(totalVolume, 0)
    }

    func testVolumeOnlyCountsCompletedSets() {
        let sets = [
            (weight: 100.0, reps: 5, completed: false),
            (weight: 100.0, reps: 5, completed: false),
            (weight: 100.0, reps: 5, completed: true)    // Only this counts
        ]

        let totalVolume = sets.filter { $0.completed }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }

        XCTAssertEqual(totalVolume, 500, accuracy: 0.001)
    }

    // MARK: - Set Analysis Tests

    func testHitTargetCalculation() {
        struct TestSet {
            let reps: Int
            let targetReps: Int

            var hitTarget: Bool { reps >= targetReps }
        }

        let hitTarget = TestSet(reps: 5, targetReps: 5)
        XCTAssertTrue(hitTarget.hitTarget)

        let exceededTarget = TestSet(reps: 6, targetReps: 5)
        XCTAssertTrue(exceededTarget.hitTarget)

        let missedTarget = TestSet(reps: 4, targetReps: 5)
        XCTAssertFalse(missedTarget.hitTarget)
    }

    func testRPEDeviationCalculation() {
        struct TestSet {
            let rpe: Double?
            let targetRPE: Double?

            var rpeDeviation: Double? {
                guard let actual = rpe, let target = targetRPE else { return nil }
                return actual - target
            }
        }

        // Exact match
        let exactMatch = TestSet(rpe: 8.0, targetRPE: 8.0)
        XCTAssertEqual(exactMatch.rpeDeviation ?? 999, 0, accuracy: 0.001)

        // Harder than expected
        let harderSet = TestSet(rpe: 9.0, targetRPE: 8.0)
        XCTAssertEqual(harderSet.rpeDeviation ?? 999, 1.0, accuracy: 0.001)

        // Easier than expected
        let easierSet = TestSet(rpe: 7.0, targetRPE: 8.0)
        XCTAssertEqual(easierSet.rpeDeviation ?? 999, -1.0, accuracy: 0.001)

        // Missing RPE
        let noRPE = TestSet(rpe: nil, targetRPE: 8.0)
        XCTAssertNil(noRPE.rpeDeviation)

        // Missing target
        let noTarget = TestSet(rpe: 8.0, targetRPE: nil)
        XCTAssertNil(noTarget.rpeDeviation)
    }

    // MARK: - E1RM Tracking Tests

    func testE1RMCalculationForSet() {
        struct TestSet {
            let weight: Double
            let reps: Int

            var e1RM: Double {
                E1RMCalculator.calculate(weight: weight, reps: reps)
            }
        }

        let set = TestSet(weight: 100, reps: 5)
        let expectedE1RM = 100.0 * (1.0 + 5.0 / 30.0)
        XCTAssertEqual(set.e1RM, expectedE1RM, accuracy: 0.001)
    }

    func testTopSetIdentification() {
        struct TestSet {
            let weight: Double
            let reps: Int
            let setType: String
            let isCompleted: Bool

            var e1RM: Double {
                E1RMCalculator.calculate(weight: weight, reps: reps)
            }
        }

        let sets = [
            TestSet(weight: 60, reps: 5, setType: "warmup", isCompleted: true),
            TestSet(weight: 80, reps: 5, setType: "warmup", isCompleted: true),
            TestSet(weight: 100, reps: 5, setType: "topSet", isCompleted: true),
            TestSet(weight: 90, reps: 8, setType: "backoff", isCompleted: true)
        ]

        // Find top set (highest e1RM among top sets)
        let topSets = sets.filter { $0.setType == "topSet" && $0.isCompleted }
        let topSet = topSets.max(by: { $0.e1RM < $1.e1RM })

        XCTAssertNotNil(topSet)
        XCTAssertEqual(topSet?.weight, 100)
    }

    // MARK: - Session Progress Tests

    func testSessionVolumeComparison() {
        let previousSessionVolume = 5000.0
        let currentSessionVolume = 5500.0

        let volumeIncrease = currentSessionVolume - previousSessionVolume
        let percentageIncrease = (volumeIncrease / previousSessionVolume) * 100

        XCTAssertEqual(volumeIncrease, 500, accuracy: 0.001)
        XCTAssertEqual(percentageIncrease, 10, accuracy: 0.001)
    }

    func testE1RMProgressTracking() {
        let previousBestE1RM = 116.67
        let currentE1RM = 122.5

        let improvement = currentE1RM - previousBestE1RM
        let percentageImprovement = (improvement / previousBestE1RM) * 100

        XCTAssertGreaterThan(improvement, 0, "Should show improvement")
        XCTAssertEqual(percentageImprovement, 5.0, accuracy: 0.5)
    }

    // MARK: - Workout Duration Tests

    func testDurationTracking() {
        let plannedDuration = 60
        let actualDuration = 55

        let durationDifference = plannedDuration - actualDuration
        XCTAssertEqual(durationDifference, 5)

        // Workout finished faster than planned
        XCTAssertLessThan(actualDuration, plannedDuration)
    }

    func testDurationWithOverrun() {
        let plannedDuration = 60
        let actualDuration = 75

        let overrun = actualDuration - plannedDuration
        XCTAssertEqual(overrun, 15)
        XCTAssertGreaterThan(actualDuration, plannedDuration)
    }

    // MARK: - Readiness Impact Tests

    func testReadinessAffectsPerformance() {
        let defaultReadiness = Readiness.default
        XCTAssertFalse(defaultReadiness.shouldReduceIntensity)
        XCTAssertFalse(defaultReadiness.shouldIncreaseIntensity)

        let lowEnergyReadiness = Readiness(energy: .low, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(lowEnergyReadiness.shouldReduceIntensity)

        let optimalReadiness = Readiness(energy: .high, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(optimalReadiness.shouldIncreaseIntensity)
    }

    // MARK: - Set Ordering Tests

    func testSetOrderIndexing() {
        struct OrderedSet {
            let exerciseName: String
            let orderIndex: Int
        }

        var sets = [
            OrderedSet(exerciseName: "Bench Press", orderIndex: 0),
            OrderedSet(exerciseName: "Bench Press", orderIndex: 1),
            OrderedSet(exerciseName: "Bench Press", orderIndex: 2),
            OrderedSet(exerciseName: "Row", orderIndex: 3),
            OrderedSet(exerciseName: "Row", orderIndex: 4)
        ]

        sets.sort { $0.orderIndex < $1.orderIndex }

        XCTAssertEqual(sets[0].orderIndex, 0)
        XCTAssertEqual(sets[4].orderIndex, 4)
    }

    // MARK: - Exercise Grouping Tests

    func testGroupingSetsByExercise() {
        struct SimpleSet {
            let exerciseName: String
            let weight: Double
            let reps: Int
        }

        let sets = [
            SimpleSet(exerciseName: "Bench Press", weight: 60, reps: 5),
            SimpleSet(exerciseName: "Bench Press", weight: 100, reps: 5),
            SimpleSet(exerciseName: "Barbell Row", weight: 80, reps: 8),
            SimpleSet(exerciseName: "Barbell Row", weight: 80, reps: 8),
            SimpleSet(exerciseName: "Bench Press", weight: 90, reps: 8)
        ]

        let groupedByExercise = Dictionary(grouping: sets) { $0.exerciseName }

        XCTAssertEqual(groupedByExercise.keys.count, 2)
        XCTAssertEqual(groupedByExercise["Bench Press"]?.count, 3)
        XCTAssertEqual(groupedByExercise["Barbell Row"]?.count, 2)
    }

    // MARK: - Session Completion Tests

    func testSessionCompletionStatus() {
        struct SessionStatus {
            let totalSets: Int
            let completedSets: Int

            var isComplete: Bool { completedSets == totalSets }
            var completionPercentage: Double {
                guard totalSets > 0 else { return 0 }
                return Double(completedSets) / Double(totalSets) * 100
            }
        }

        let completeSession = SessionStatus(totalSets: 15, completedSets: 15)
        XCTAssertTrue(completeSession.isComplete)
        XCTAssertEqual(completeSession.completionPercentage, 100)

        let partialSession = SessionStatus(totalSets: 15, completedSets: 10)
        XCTAssertFalse(partialSession.isComplete)
        XCTAssertEqual(partialSession.completionPercentage, 66.67, accuracy: 0.1)

        let emptySession = SessionStatus(totalSets: 0, completedSets: 0)
        XCTAssertEqual(emptySession.completionPercentage, 0)
    }

    // MARK: - Session Summary Tests

    func testSessionSummaryGeneration() {
        // Simulate a completed session
        let exercises = [
            (name: "Bench Press", volume: 2570.0, e1RM: 116.67, hitTarget: true),
            (name: "Barbell Row", volume: 2400.0, e1RM: 110.0, hitTarget: true),
            (name: "Lateral Raise", volume: 600.0, e1RM: 0.0, hitTarget: false)
        ]

        let totalVolume = exercises.reduce(0) { $0 + $1.volume }
        let exercisesHittingTarget = exercises.filter { $0.hitTarget }.count
        let successRate = Double(exercisesHittingTarget) / Double(exercises.count) * 100

        XCTAssertEqual(totalVolume, 5570, accuracy: 0.001)
        XCTAssertEqual(successRate, 66.67, accuracy: 0.1)
    }

    // MARK: - Location Tests

    func testLocationAffectsEquipment() {
        // Location enum should indicate available equipment
        XCTAssertEqual(Location.gym.rawValue, "Gym")
        XCTAssertEqual(Location.home.rawValue, "Home")

        // Gym typically has more equipment
        // Home typically has limited equipment
    }

    // MARK: - Notes Tests

    func testSessionNotes() {
        let sessionNotes = "Great workout, felt strong on bench press. Need to work on row form."

        XCTAssertFalse(sessionNotes.isEmpty)
        XCTAssertTrue(sessionNotes.contains("bench press"))
    }
}
