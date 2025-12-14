import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var movementPattern: MovementPattern
    var primaryMusclesData: Data?
    var secondaryMusclesData: Data?
    var equipmentRequiredData: Data?
    var isCompound: Bool
    var defaultProgressionType: ProgressionType
    var instructions: String?

    init(
        id: UUID = UUID(),
        name: String,
        movementPattern: MovementPattern,
        primaryMuscles: [Muscle],
        secondaryMuscles: [Muscle] = [],
        equipmentRequired: [Equipment],
        isCompound: Bool = true,
        defaultProgressionType: ProgressionType = .topSetBackoff,
        instructions: String? = nil
    ) {
        self.id = id
        self.name = name
        self.movementPattern = movementPattern
        self.primaryMusclesData = try? JSONEncoder().encode(primaryMuscles)
        self.secondaryMusclesData = try? JSONEncoder().encode(secondaryMuscles)
        self.equipmentRequiredData = try? JSONEncoder().encode(equipmentRequired)
        self.isCompound = isCompound
        self.defaultProgressionType = defaultProgressionType
        self.instructions = instructions
    }

    var primaryMuscles: [Muscle] {
        get {
            guard let data = primaryMusclesData else { return [] }
            return (try? JSONDecoder().decode([Muscle].self, from: data)) ?? []
        }
        set {
            primaryMusclesData = try? JSONEncoder().encode(newValue)
        }
    }

    var secondaryMuscles: [Muscle] {
        get {
            guard let data = secondaryMusclesData else { return [] }
            return (try? JSONDecoder().decode([Muscle].self, from: data)) ?? []
        }
        set {
            secondaryMusclesData = try? JSONEncoder().encode(newValue)
        }
    }

    var equipmentRequired: [Equipment] {
        get {
            guard let data = equipmentRequiredData else { return [] }
            return (try? JSONDecoder().decode([Equipment].self, from: data)) ?? []
        }
        set {
            equipmentRequiredData = try? JSONEncoder().encode(newValue)
        }
    }

    var allMuscles: [Muscle] {
        primaryMuscles + secondaryMuscles
    }

    var defaultWeightIncrement: Double {
        if isCompound && equipmentRequired.contains(.barbell) {
            return 2.5 // kg
        } else if equipmentRequired.contains(.dumbbell) {
            return 2.0 // kg per dumbbell
        }
        return 2.5
    }
}

// MARK: - Exercise Reference (for JSON/LLM communication)
struct ExerciseReference: Codable, Hashable {
    let id: UUID
    let name: String

    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
