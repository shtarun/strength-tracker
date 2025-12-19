import Foundation
import SwiftData

/// Represents a paused/in-progress workout that can be resumed later
@Model
final class PausedWorkout {
    var id: UUID
    var pausedAt: Date
    var startedAt: Date
    var currentExerciseIndex: Int

    // Serialized workout state
    var exerciseSetsData: Data? // [UUID: [SetSnapshot]]
    var planData: Data? // TodayPlanResponse

    @Relationship var template: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        template: WorkoutTemplate? = nil,
        pausedAt: Date = Date(),
        startedAt: Date = Date(),
        currentExerciseIndex: Int = 0,
        exerciseSets: [UUID: [SetSnapshot]] = [:],
        plan: TodayPlanResponse? = nil
    ) {
        self.id = id
        self.template = template
        self.pausedAt = pausedAt
        self.startedAt = startedAt
        self.currentExerciseIndex = currentExerciseIndex
        self.exerciseSetsData = try? JSONEncoder().encode(exerciseSets)
        self.planData = plan.flatMap { try? JSONEncoder().encode($0) }
    }

    var exerciseSets: [UUID: [SetSnapshot]] {
        get {
            guard let data = exerciseSetsData else { return [:] }
            return (try? JSONDecoder().decode([UUID: [SetSnapshot]].self, from: data)) ?? [:]
        }
        set {
            exerciseSetsData = try? JSONEncoder().encode(newValue)
        }
    }

    var plan: TodayPlanResponse? {
        get {
            guard let data = planData else { return nil }
            return try? JSONDecoder().decode(TodayPlanResponse.self, from: data)
        }
        set {
            planData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }

    /// Duration elapsed before pausing
    var elapsedDuration: TimeInterval {
        pausedAt.timeIntervalSince(startedAt)
    }

    /// Time since workout was paused
    var pausedDuration: TimeInterval {
        Date().timeIntervalSince(pausedAt)
    }

    /// Whether the paused workout is still valid (not too old)
    var isValid: Bool {
        // Consider workout invalid if paused for more than 24 hours
        pausedDuration < 24 * 60 * 60
    }
}

/// Snapshot of a WorkoutSet for serialization
struct SetSnapshot: Codable, Identifiable {
    let id: UUID
    let exerciseId: UUID
    let setType: SetType
    var weight: Double
    var targetReps: Int
    var reps: Int
    var rpe: Double?
    var targetRPE: Double?
    var isCompleted: Bool
    var notes: String?
    var timestamp: Date
    var orderIndex: Int

    init(from set: WorkoutSet) {
        self.id = set.id
        self.exerciseId = set.exercise?.id ?? UUID()
        self.setType = set.setType
        self.weight = set.weight
        self.targetReps = set.targetReps
        self.reps = set.reps
        self.rpe = set.rpe
        self.targetRPE = set.targetRPE
        self.isCompleted = set.isCompleted
        self.notes = set.notes
        self.timestamp = set.timestamp
        self.orderIndex = set.orderIndex
    }

    func toWorkoutSet(exercise: Exercise?) -> WorkoutSet {
        WorkoutSet(
            id: id,
            exercise: exercise,
            setType: setType,
            weight: weight,
            targetReps: targetReps,
            reps: reps,
            rpe: rpe,
            targetRPE: targetRPE,
            isCompleted: isCompleted,
            notes: notes,
            timestamp: timestamp,
            orderIndex: orderIndex
        )
    }
}
