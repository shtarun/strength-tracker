import Foundation
import SwiftData

@MainActor
class ExerciseLibrary {
    static let shared = ExerciseLibrary()

    private init() {}

    func seedExercises(in context: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let exercises = createAllExercises()
        for exercise in exercises {
            context.insert(exercise)
        }

        try? context.save()
    }

    private func createAllExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        // MARK: - Horizontal Push (Chest)
        exercises.append(Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.barbell, .bench, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Incline Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .frontDelt],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.barbell, .bench, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Dumbbell Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Incline Dumbbell Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .frontDelt],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Floor Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .triceps],
            secondaryMuscles: [.frontDelt],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Push-ups",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Dips",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .triceps],
            secondaryMuscles: [.frontDelt],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Cable Fly",
            movementPattern: .isolation,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Machine Chest Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.machine],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Vertical Push (Shoulders)
        exercises.append(Exercise(
            name: "Overhead Press",
            movementPattern: .verticalPush,
            primaryMuscles: [.frontDelt, .sideDelt],
            secondaryMuscles: [.triceps, .upperBack],
            equipmentRequired: [.barbell, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Dumbbell Shoulder Press",
            movementPattern: .verticalPush,
            primaryMuscles: [.frontDelt, .sideDelt],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Lateral Raise",
            movementPattern: .isolation,
            primaryMuscles: [.sideDelt],
            secondaryMuscles: [],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Face Pull",
            movementPattern: .isolation,
            primaryMuscles: [.rearDelt, .upperBack],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Rear Delt Fly",
            movementPattern: .isolation,
            primaryMuscles: [.rearDelt],
            secondaryMuscles: [.upperBack],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Horizontal Pull (Back - Rows)
        exercises.append(Exercise(
            name: "Barbell Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.rearDelt, .biceps],
            equipmentRequired: [.barbell],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Dumbbell Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.rearDelt, .biceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Chest Supported Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.rearDelt, .biceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Cable Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.cable],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Inverted Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.bodyweight, .pullUpBar],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Vertical Pull (Back - Pulldowns/Pull-ups)
        exercises.append(Exercise(
            name: "Pull-ups",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats, .upperBack],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.pullUpBar],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Chin-ups",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats, .biceps],
            secondaryMuscles: [.upperBack],
            equipmentRequired: [.pullUpBar],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Lat Pulldown",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats],
            secondaryMuscles: [.upperBack, .biceps],
            equipmentRequired: [.cable],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Banded Pull-ups",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats, .upperBack],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.pullUpBar, .bands],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Squat Pattern (Quads)
        exercises.append(Exercise(
            name: "Barbell Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipmentRequired: [.barbell, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Front Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .core],
            equipmentRequired: [.barbell, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Goblet Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.core],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Leg Press",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Hack Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.machine],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Leg Extension",
            movementPattern: .isolation,
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Hinge Pattern (Hamstrings/Glutes)
        exercises.append(Exercise(
            name: "Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes, .lowerBack],
            secondaryMuscles: [.quads, .upperBack, .traps],
            equipmentRequired: [.barbell],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Romanian Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [.barbell],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Dumbbell Romanian Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Leg Curl",
            movementPattern: .isolation,
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Lunge Pattern
        exercises.append(Exercise(
            name: "Bulgarian Split Squat",
            movementPattern: .lunge,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Walking Lunges",
            movementPattern: .lunge,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Arms (Biceps)
        exercises.append(Exercise(
            name: "Barbell Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipmentRequired: [.barbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Dumbbell Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Cable Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Band Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipmentRequired: [.bands],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Arms (Triceps)
        exercises.append(Exercise(
            name: "Tricep Pushdown",
            movementPattern: .isolation,
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Overhead Tricep Extension",
            movementPattern: .isolation,
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Close Grip Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.triceps, .chest],
            secondaryMuscles: [.frontDelt],
            equipmentRequired: [.barbell, .bench, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff
        ))

        exercises.append(Exercise(
            name: "Diamond Push-ups",
            movementPattern: .horizontalPush,
            primaryMuscles: [.triceps],
            secondaryMuscles: [.chest],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Calves
        exercises.append(Exercise(
            name: "Standing Calf Raise",
            movementPattern: .isolation,
            primaryMuscles: [.calves],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        exercises.append(Exercise(
            name: "Seated Calf Raise",
            movementPattern: .isolation,
            primaryMuscles: [.calves],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        // MARK: - Core
        exercises.append(Exercise(
            name: "Plank",
            movementPattern: .isolation,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets
        ))

        exercises.append(Exercise(
            name: "Cable Crunch",
            movementPattern: .isolation,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression
        ))

        return exercises
    }

    func getExercise(named name: String, from context: ModelContext) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.name == name }
        )
        return try? context.fetch(descriptor).first
    }

    func getExercises(for pattern: MovementPattern, from context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.movementPattern == pattern }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getExercises(targeting muscle: Muscle, from context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.primaryMuscles.contains(muscle) || $0.secondaryMuscles.contains(muscle) }
    }

    func getAvailableExercises(for equipment: Set<Equipment>, from context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { exercise in
            Set(exercise.equipmentRequired).isSubset(of: equipment)
        }
    }
}
