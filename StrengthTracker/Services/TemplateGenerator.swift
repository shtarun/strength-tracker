import Foundation
import SwiftData

enum TemplateGenerator {

    static func generateDefaultTemplates(
        for profile: UserProfile,
        equipment: EquipmentProfile,
        in context: ModelContext
    ) {
        let exercises = fetchAllExercises(from: context)
        let availableEquipment = equipment.availableEquipment

        print("📋 TemplateGenerator: Found \(exercises.count) exercises")
        print("📋 TemplateGenerator: Available equipment: \(availableEquipment.map { $0.rawValue })")

        guard !exercises.isEmpty else {
            print("⚠️ TemplateGenerator: No exercises found! Templates will be empty.")
            return
        }

        switch profile.preferredSplit {
        case .upperLower:
            generateUpperLowerSplit(
                goal: profile.goal,
                exercises: exercises,
                equipment: availableEquipment,
                in: context
            )
        case .ppl:
            generatePPLSplit(
                goal: profile.goal,
                exercises: exercises,
                equipment: availableEquipment,
                in: context
            )
        case .fullBody:
            generateFullBodySplit(
                goal: profile.goal,
                exercises: exercises,
                equipment: availableEquipment,
                in: context
            )
        case .custom:
            break
        }

        try? context.save()
    }

    private static func fetchAllExercises(from context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private static func findExercise(
        named name: String,
        in exercises: [Exercise],
        availableEquipment: Set<Equipment>
    ) -> Exercise? {
        // First try exact match
        if let exercise = exercises.first(where: { $0.name == name }) {
            if Set(exercise.equipmentRequired).isSubset(of: availableEquipment) {
                return exercise
            }
        }
        return nil
    }

    private static func findExerciseOrSubstitute(
        named name: String,
        fallbacks: [String],
        in exercises: [Exercise],
        availableEquipment: Set<Equipment>
    ) -> Exercise? {
        // Try primary
        if let exercise = findExercise(named: name, in: exercises, availableEquipment: availableEquipment) {
            return exercise
        }

        // Try fallbacks
        for fallback in fallbacks {
            if let exercise = findExercise(named: fallback, in: exercises, availableEquipment: availableEquipment) {
                return exercise
            }
        }

        return nil
    }

    // MARK: - Upper/Lower Split

    private static func generateUpperLowerSplit(
        goal: Goal,
        exercises: [Exercise],
        equipment: Set<Equipment>,
        in context: ModelContext
    ) {
        let prescription = prescriptionFor(goal: goal)

        // Upper A
        let upperA = WorkoutTemplate(name: "Upper A", dayNumber: 1, targetDuration: 60)
        addExercises(to: upperA, specs: [
            ("Bench Press", ["Dumbbell Bench Press", "Floor Press", "Push-ups"], prescription, false),
            ("Barbell Row", ["Dumbbell Row", "Cable Row", "Inverted Row"], prescription, false),
            ("Overhead Press", ["Dumbbell Shoulder Press"], prescription, false),
            ("Pull-ups", ["Lat Pulldown", "Banded Pull-ups"], .hypertrophy, false),
            ("Lateral Raise", ["Face Pull"], .hypertrophy, true),
            ("Tricep Pushdown", ["Overhead Tricep Extension", "Diamond Push-ups"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(upperA)

        // Lower A
        let lowerA = WorkoutTemplate(name: "Lower A", dayNumber: 2, targetDuration: 60)
        addExercises(to: lowerA, specs: [
            ("Barbell Squat", ["Goblet Squat", "Leg Press", "Bulgarian Split Squat"], prescription, false),
            ("Romanian Deadlift", ["Dumbbell Romanian Deadlift", "Leg Curl"], prescription, false),
            ("Leg Press", ["Goblet Squat", "Bulgarian Split Squat"], .hypertrophy, false),
            ("Leg Curl", ["Dumbbell Romanian Deadlift"], .hypertrophy, false),
            ("Standing Calf Raise", ["Seated Calf Raise"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(lowerA)

        // Upper B
        let upperB = WorkoutTemplate(name: "Upper B", dayNumber: 3, targetDuration: 60)
        addExercises(to: upperB, specs: [
            ("Overhead Press", ["Dumbbell Shoulder Press"], prescription, false),
            ("Lat Pulldown", ["Pull-ups", "Chin-ups", "Banded Pull-ups"], prescription, false),
            ("Incline Dumbbell Press", ["Incline Bench Press", "Dumbbell Bench Press"], .hypertrophy, false),
            ("Cable Row", ["Dumbbell Row", "Chest Supported Row"], .hypertrophy, false),
            ("Face Pull", ["Rear Delt Fly"], .hypertrophy, true),
            ("Barbell Curl", ["Dumbbell Curl", "Cable Curl"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(upperB)

        // Lower B
        let lowerB = WorkoutTemplate(name: "Lower B", dayNumber: 4, targetDuration: 60)
        addExercises(to: lowerB, specs: [
            ("Deadlift", ["Romanian Deadlift", "Dumbbell Romanian Deadlift"], prescription, false),
            ("Front Squat", ["Goblet Squat", "Leg Press"], .hypertrophy, false),
            ("Bulgarian Split Squat", ["Walking Lunges", "Goblet Squat"], .hypertrophy, false),
            ("Leg Extension", ["Goblet Squat"], .hypertrophy, true),
            ("Standing Calf Raise", ["Seated Calf Raise"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(lowerB)
    }

    // MARK: - PPL Split

    private static func generatePPLSplit(
        goal: Goal,
        exercises: [Exercise],
        equipment: Set<Equipment>,
        in context: ModelContext
    ) {
        let prescription = prescriptionFor(goal: goal)

        // Push
        let push = WorkoutTemplate(name: "Push", dayNumber: 1, targetDuration: 60)
        addExercises(to: push, specs: [
            ("Bench Press", ["Dumbbell Bench Press", "Floor Press"], prescription, false),
            ("Overhead Press", ["Dumbbell Shoulder Press"], prescription, false),
            ("Incline Dumbbell Press", ["Incline Bench Press"], .hypertrophy, false),
            ("Lateral Raise", [], .hypertrophy, false),
            ("Tricep Pushdown", ["Overhead Tricep Extension"], .hypertrophy, true),
            ("Cable Fly", ["Dips", "Push-ups"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(push)

        // Pull
        let pull = WorkoutTemplate(name: "Pull", dayNumber: 2, targetDuration: 60)
        addExercises(to: pull, specs: [
            ("Barbell Row", ["Dumbbell Row", "Cable Row"], prescription, false),
            ("Pull-ups", ["Lat Pulldown", "Chin-ups"], prescription, false),
            ("Cable Row", ["Chest Supported Row", "Dumbbell Row"], .hypertrophy, false),
            ("Face Pull", ["Rear Delt Fly"], .hypertrophy, false),
            ("Barbell Curl", ["Dumbbell Curl", "Cable Curl"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(pull)

        // Legs
        let legs = WorkoutTemplate(name: "Legs", dayNumber: 3, targetDuration: 60)
        addExercises(to: legs, specs: [
            ("Barbell Squat", ["Goblet Squat", "Leg Press"], prescription, false),
            ("Romanian Deadlift", ["Dumbbell Romanian Deadlift"], prescription, false),
            ("Leg Press", ["Bulgarian Split Squat", "Goblet Squat"], .hypertrophy, false),
            ("Leg Curl", ["Dumbbell Romanian Deadlift"], .hypertrophy, false),
            ("Leg Extension", ["Bulgarian Split Squat"], .hypertrophy, true),
            ("Standing Calf Raise", ["Seated Calf Raise"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(legs)
    }

    // MARK: - Full Body Split

    private static func generateFullBodySplit(
        goal: Goal,
        exercises: [Exercise],
        equipment: Set<Equipment>,
        in context: ModelContext
    ) {
        let prescription = prescriptionFor(goal: goal)

        // Day A
        let dayA = WorkoutTemplate(name: "Full Body A", dayNumber: 1, targetDuration: 60)
        addExercises(to: dayA, specs: [
            ("Barbell Squat", ["Goblet Squat", "Leg Press"], prescription, false),
            ("Bench Press", ["Dumbbell Bench Press", "Floor Press"], prescription, false),
            ("Barbell Row", ["Dumbbell Row", "Cable Row"], prescription, false),
            ("Romanian Deadlift", ["Dumbbell Romanian Deadlift"], .hypertrophy, false),
            ("Lateral Raise", [], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(dayA)

        // Day B
        let dayB = WorkoutTemplate(name: "Full Body B", dayNumber: 2, targetDuration: 60)
        addExercises(to: dayB, specs: [
            ("Deadlift", ["Romanian Deadlift"], prescription, false),
            ("Overhead Press", ["Dumbbell Shoulder Press"], prescription, false),
            ("Pull-ups", ["Lat Pulldown", "Chin-ups"], prescription, false),
            ("Leg Press", ["Bulgarian Split Squat", "Goblet Squat"], .hypertrophy, false),
            ("Dips", ["Tricep Pushdown", "Push-ups"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(dayB)

        // Day C
        let dayC = WorkoutTemplate(name: "Full Body C", dayNumber: 3, targetDuration: 60)
        addExercises(to: dayC, specs: [
            ("Front Squat", ["Goblet Squat", "Barbell Squat"], prescription, false),
            ("Incline Bench Press", ["Incline Dumbbell Press", "Dumbbell Bench Press"], prescription, false),
            ("Cable Row", ["Dumbbell Row", "Barbell Row"], prescription, false),
            ("Bulgarian Split Squat", ["Walking Lunges"], .hypertrophy, false),
            ("Face Pull", ["Rear Delt Fly"], .hypertrophy, true)
        ], exercises: exercises, equipment: equipment, context: context)
        context.insert(dayC)
    }

    // MARK: - Helpers

    private static func prescriptionFor(goal: Goal) -> Prescription {
        switch goal {
        case .strength:
            return .strength
        case .hypertrophy:
            return .hypertrophy
        case .both:
            return .default
        }
    }

    private static func addExercises(
        to template: WorkoutTemplate,
        specs: [(name: String, fallbacks: [String], prescription: Prescription, isOptional: Bool)],
        exercises: [Exercise],
        equipment: Set<Equipment>,
        context: ModelContext
    ) {
        var orderIndex = 0
        print("📋 TemplateGenerator: Adding exercises to '\(template.name)'")

        for spec in specs {
            if let exercise = findExerciseOrSubstitute(
                named: spec.name,
                fallbacks: spec.fallbacks,
                in: exercises,
                availableEquipment: equipment
            ) {
                let templateExercise = ExerciseTemplate(
                    exercise: exercise,
                    orderIndex: orderIndex,
                    isOptional: spec.isOptional,
                    prescription: spec.prescription
                )
                templateExercise.template = template
                template.exercises.append(templateExercise)
                context.insert(templateExercise)
                print("   ✅ Added: \(exercise.name) (index \(orderIndex))")
                orderIndex += 1
            } else {
                print("   ❌ Could not find: \(spec.name) or fallbacks: \(spec.fallbacks)")
            }
        }

        print("📋 TemplateGenerator: Template '\(template.name)' now has \(template.exercises.count) exercises")
    }
}
