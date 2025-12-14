import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var dayNumber: Int
    var targetDuration: Int // minutes
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var exercises: [ExerciseTemplate]

    init(
        id: UUID = UUID(),
        name: String,
        dayNumber: Int,
        targetDuration: Int = 60,
        exercises: [ExerciseTemplate] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dayNumber = dayNumber
        self.targetDuration = targetDuration
        self.exercises = exercises
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sortedExercises: [ExerciseTemplate] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
final class ExerciseTemplate {
    var id: UUID
    var orderIndex: Int
    var isOptional: Bool
    var prescriptionData: Data?

    @Relationship var exercise: Exercise?
    @Relationship(inverse: \WorkoutTemplate.exercises) var template: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        orderIndex: Int,
        isOptional: Bool = false,
        prescription: Prescription = .default
    ) {
        self.id = id
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.isOptional = isOptional
        self.prescriptionData = try? JSONEncoder().encode(prescription)
    }

    var prescription: Prescription {
        get {
            guard let data = prescriptionData else { return .default }
            return (try? JSONDecoder().decode(Prescription.self, from: data)) ?? .default
        }
        set {
            prescriptionData = try? JSONEncoder().encode(newValue)
        }
    }
}

struct Prescription: Codable, Equatable {
    var progressionType: ProgressionType
    var topSetRepsMin: Int
    var topSetRepsMax: Int
    var topSetRPECap: Double
    var backoffSets: Int
    var backoffRepsMin: Int
    var backoffRepsMax: Int
    var backoffLoadDropPercent: Double
    var workingSets: Int // for double progression / straight sets

    static let `default` = Prescription(
        progressionType: .topSetBackoff,
        topSetRepsMin: 4,
        topSetRepsMax: 6,
        topSetRPECap: 8.0,
        backoffSets: 3,
        backoffRepsMin: 6,
        backoffRepsMax: 10,
        backoffLoadDropPercent: 0.10,
        workingSets: 3
    )

    static let hypertrophy = Prescription(
        progressionType: .doubleProgression,
        topSetRepsMin: 8,
        topSetRepsMax: 12,
        topSetRPECap: 8.5,
        backoffSets: 0,
        backoffRepsMin: 8,
        backoffRepsMax: 12,
        backoffLoadDropPercent: 0,
        workingSets: 3
    )

    static let strength = Prescription(
        progressionType: .topSetBackoff,
        topSetRepsMin: 3,
        topSetRepsMax: 5,
        topSetRPECap: 8.0,
        backoffSets: 3,
        backoffRepsMin: 5,
        backoffRepsMax: 8,
        backoffLoadDropPercent: 0.12,
        workingSets: 1
    )

    var topSetRepsRange: String {
        "\(topSetRepsMin)-\(topSetRepsMax)"
    }

    var backoffRepsRange: String {
        "\(backoffRepsMin)-\(backoffRepsMax)"
    }
}
