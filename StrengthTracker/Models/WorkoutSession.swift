import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var location: Location
    var readinessData: Data?
    var plannedDuration: Int // minutes
    var actualDuration: Int? // minutes
    var notes: String?
    var isCompleted: Bool
    var insightText: String?
    var insightAction: String?

    @Relationship var template: WorkoutTemplate?
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
    @Relationship var planWeek: PlanWeek?

    init(
        id: UUID = UUID(),
        template: WorkoutTemplate? = nil,
        date: Date = Date(),
        location: Location = .gym,
        readiness: Readiness = .default,
        plannedDuration: Int = 60,
        actualDuration: Int? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.template = template
        self.date = date
        self.location = location
        self.readinessData = try? JSONEncoder().encode(readiness)
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.notes = notes
        self.isCompleted = isCompleted
        self.sets = sets
    }

    var readiness: Readiness {
        get {
            guard let data = readinessData else { return .default }
            return (try? JSONDecoder().decode(Readiness.self, from: data)) ?? .default
        }
        set {
            readinessData = try? JSONEncoder().encode(newValue)
        }
    }

    var completedSets: [WorkoutSet] {
        sets.filter { $0.isCompleted }
    }

    var totalVolume: Double {
        completedSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var exercisesPerformed: [Exercise] {
        let exerciseIds = Set(completedSets.compactMap { $0.exercise?.id })
        return completedSets.compactMap { $0.exercise }.filter { exerciseIds.contains($0.id) }
    }

    func sets(for exercise: Exercise) -> [WorkoutSet] {
        sets.filter { $0.exercise?.id == exercise.id }
    }

    func topSet(for exercise: Exercise) -> WorkoutSet? {
        sets(for: exercise)
            .filter { $0.setType == .topSet && $0.isCompleted }
            .max { E1RMCalculator.calculate(weight: $0.weight, reps: $0.reps) < E1RMCalculator.calculate(weight: $1.weight, reps: $1.reps) }
    }
}
