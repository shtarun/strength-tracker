import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID
    var setType: SetType
    var weight: Double // always stored in kg
    var targetReps: Int
    var reps: Int
    var rpe: Double?
    var targetRPE: Double?
    var isCompleted: Bool
    var notes: String?
    var timestamp: Date
    var orderIndex: Int

    @Relationship var exercise: Exercise?
    @Relationship(inverse: \WorkoutSession.sets) var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        setType: SetType = .working,
        weight: Double = 0,
        targetReps: Int = 0,
        reps: Int = 0,
        rpe: Double? = nil,
        targetRPE: Double? = nil,
        isCompleted: Bool = false,
        notes: String? = nil,
        timestamp: Date = Date(),
        orderIndex: Int = 0
    ) {
        self.id = id
        self.exercise = exercise
        self.setType = setType
        self.weight = weight
        self.targetReps = targetReps
        self.reps = reps
        self.rpe = rpe
        self.targetRPE = targetRPE
        self.isCompleted = isCompleted
        self.notes = notes
        self.timestamp = timestamp
        self.orderIndex = orderIndex
    }

    var e1RM: Double {
        E1RMCalculator.calculate(weight: weight, reps: reps)
    }

    var hitTarget: Bool {
        reps >= targetReps
    }

    var rpeDeviation: Double? {
        guard let actual = rpe, let target = targetRPE else { return nil }
        return actual - target
    }

    func duplicate() -> WorkoutSet {
        WorkoutSet(
            exercise: exercise,
            setType: setType,
            weight: weight,
            targetReps: targetReps,
            reps: reps,
            rpe: nil,
            targetRPE: targetRPE,
            isCompleted: false,
            orderIndex: orderIndex + 1
        )
    }
}

// MARK: - Set History (for querying)
struct SetHistory: Codable {
    let date: Date
    let weight: Double
    let reps: Int
    let rpe: Double?
    let setType: SetType
    let e1RM: Double

    init(from set: WorkoutSet, date: Date) {
        self.date = date
        self.weight = set.weight
        self.reps = set.reps
        self.rpe = set.rpe
        self.setType = set.setType
        self.e1RM = set.e1RM
    }
}
