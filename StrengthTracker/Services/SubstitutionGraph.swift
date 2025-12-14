import Foundation
import SwiftData

/// Manages exercise substitutions based on equipment availability and pain flags
actor SubstitutionGraph {
    static let shared = SubstitutionGraph()

    private init() {}

    /// Graph of exercise substitutions by exercise name
    /// Format: [ExerciseName: [AlternativeNames in priority order]]
    private let substitutionMap: [String: [String]] = [
        // Horizontal Push
        "Bench Press": ["Dumbbell Bench Press", "Floor Press", "Push-ups", "Machine Chest Press"],
        "Incline Bench Press": ["Incline Dumbbell Press", "Dumbbell Bench Press", "Push-ups"],
        "Dumbbell Bench Press": ["Bench Press", "Floor Press", "Push-ups", "Machine Chest Press"],
        "Floor Press": ["Dumbbell Bench Press", "Push-ups", "Bench Press"],
        "Push-ups": ["Dumbbell Bench Press", "Floor Press", "Bench Press"],
        "Dips": ["Push-ups", "Dumbbell Bench Press", "Tricep Pushdown"],
        "Machine Chest Press": ["Dumbbell Bench Press", "Push-ups", "Floor Press"],

        // Vertical Push
        "Overhead Press": ["Dumbbell Shoulder Press", "Push-ups"],
        "Dumbbell Shoulder Press": ["Overhead Press", "Lateral Raise"],

        // Vertical Pull
        "Pull-ups": ["Lat Pulldown", "Banded Pull-ups", "Inverted Row", "Chin-ups"],
        "Chin-ups": ["Pull-ups", "Lat Pulldown", "Banded Pull-ups", "Inverted Row"],
        "Lat Pulldown": ["Pull-ups", "Banded Pull-ups", "Inverted Row", "Chin-ups"],
        "Banded Pull-ups": ["Pull-ups", "Inverted Row", "Lat Pulldown"],

        // Horizontal Pull
        "Barbell Row": ["Dumbbell Row", "Chest Supported Row", "Cable Row", "Inverted Row"],
        "Dumbbell Row": ["Barbell Row", "Chest Supported Row", "Cable Row", "Inverted Row"],
        "Chest Supported Row": ["Dumbbell Row", "Cable Row", "Barbell Row", "Inverted Row"],
        "Cable Row": ["Dumbbell Row", "Chest Supported Row", "Barbell Row", "Inverted Row"],
        "Inverted Row": ["Dumbbell Row", "Cable Row", "Barbell Row"],

        // Squat Pattern
        "Barbell Squat": ["Goblet Squat", "Leg Press", "Bulgarian Split Squat", "Front Squat"],
        "Front Squat": ["Goblet Squat", "Barbell Squat", "Leg Press", "Bulgarian Split Squat"],
        "Goblet Squat": ["Barbell Squat", "Bulgarian Split Squat", "Leg Press"],
        "Leg Press": ["Goblet Squat", "Barbell Squat", "Bulgarian Split Squat", "Hack Squat"],
        "Hack Squat": ["Leg Press", "Barbell Squat", "Goblet Squat"],

        // Hinge Pattern
        "Deadlift": ["Romanian Deadlift", "Dumbbell Romanian Deadlift"],
        "Romanian Deadlift": ["Dumbbell Romanian Deadlift", "Deadlift", "Leg Curl"],
        "Dumbbell Romanian Deadlift": ["Romanian Deadlift", "Leg Curl"],

        // Lunge Pattern
        "Bulgarian Split Squat": ["Walking Lunges", "Goblet Squat"],
        "Walking Lunges": ["Bulgarian Split Squat", "Goblet Squat"],

        // Arms - Biceps
        "Barbell Curl": ["Dumbbell Curl", "Cable Curl", "Band Curl"],
        "Dumbbell Curl": ["Barbell Curl", "Cable Curl", "Band Curl"],
        "Cable Curl": ["Dumbbell Curl", "Barbell Curl", "Band Curl"],
        "Band Curl": ["Dumbbell Curl", "Cable Curl"],

        // Arms - Triceps
        "Tricep Pushdown": ["Overhead Tricep Extension", "Diamond Push-ups", "Dips"],
        "Overhead Tricep Extension": ["Tricep Pushdown", "Diamond Push-ups", "Dips"],
        "Close Grip Bench Press": ["Diamond Push-ups", "Tricep Pushdown", "Dips"],
        "Diamond Push-ups": ["Tricep Pushdown", "Overhead Tricep Extension", "Dips"],

        // Shoulders - Isolation
        "Lateral Raise": ["Face Pull", "Rear Delt Fly"],
        "Face Pull": ["Rear Delt Fly", "Lateral Raise"],
        "Rear Delt Fly": ["Face Pull", "Dumbbell Row"],

        // Legs - Isolation
        "Leg Extension": ["Goblet Squat", "Bulgarian Split Squat"],
        "Leg Curl": ["Romanian Deadlift", "Dumbbell Romanian Deadlift"],

        // Calves
        "Standing Calf Raise": ["Seated Calf Raise"],
        "Seated Calf Raise": ["Standing Calf Raise"],

        // Core
        "Cable Crunch": ["Plank"],
        "Plank": ["Cable Crunch"]
    ]

    enum SubstitutionReason: String, Codable {
        case equipmentMissing = "Equipment not available"
        case painFlag = "Pain flag for this movement"
        case timeConstraint = "Time constraint"
        case userPreference = "User preference"
    }

    struct Substitution: Codable {
        let originalExercise: String
        let substituteExercise: String
        let reason: SubstitutionReason
    }

    /// Find substitutes for an exercise based on available equipment
    func findSubstitutes(
        for exerciseName: String,
        availableEquipment: Set<Equipment>,
        allExercises: [Exercise],
        painFlags: [PainFlag] = [],
        limit: Int = 3
    ) -> [(exercise: Exercise, reason: SubstitutionReason)] {
        guard let alternatives = substitutionMap[exerciseName] else {
            return []
        }

        let exercisesByName = Dictionary(grouping: allExercises) { $0.name }
            .compactMapValues { $0.first }

        // Get body parts with pain flags
        let painBodyParts = Set(painFlags.filter { $0.isRecent }.map { $0.bodyPart })

        var substitutes: [(exercise: Exercise, reason: SubstitutionReason)] = []

        for altName in alternatives {
            guard let altExercise = exercisesByName[altName] else { continue }

            // Check equipment availability
            let requiredEquipment = Set(altExercise.equipmentRequired)
            guard requiredEquipment.isSubset(of: availableEquipment) else { continue }

            // Check for pain flags
            let targetsMusclesWithPain = altExercise.primaryMuscles.contains { muscle in
                painBodyParts.contains(muscle.bodyPart)
            }
            if targetsMusclesWithPain { continue }

            substitutes.append((altExercise, .equipmentMissing))

            if substitutes.count >= limit { break }
        }

        return substitutes
    }

    /// Get the best substitute for an exercise
    func getBestSubstitute(
        for exercise: Exercise,
        availableEquipment: Set<Equipment>,
        allExercises: [Exercise],
        painFlags: [PainFlag] = []
    ) -> (exercise: Exercise, reason: SubstitutionReason)? {
        let subs = findSubstitutes(
            for: exercise.name,
            availableEquipment: availableEquipment,
            allExercises: allExercises,
            painFlags: painFlags,
            limit: 1
        )
        return subs.first
    }

    /// Check if exercise needs substitution
    func needsSubstitution(
        exercise: Exercise,
        availableEquipment: Set<Equipment>,
        painFlags: [PainFlag] = []
    ) -> SubstitutionReason? {
        // Check equipment
        let required = Set(exercise.equipmentRequired)
        if !required.isSubset(of: availableEquipment) {
            return .equipmentMissing
        }

        // Check pain flags
        let painBodyParts = Set(painFlags.filter { $0.isRecent }.map { $0.bodyPart })
        let targetsMusclesWithPain = exercise.primaryMuscles.contains { muscle in
            painBodyParts.contains(muscle.bodyPart)
        }
        if targetsMusclesWithPain {
            return .painFlag
        }

        return nil
    }
}
