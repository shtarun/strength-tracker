import Foundation
import SwiftData

/// Pre-built workout plan templates that users can use as starting points
struct PlanTemplateLibrary {

    /// All available pre-built plan templates
    static let templates: [PlanTemplate] = [
        beginnerStrength,
        hypertrophyBlock,
        pplPowerBuilder,
        strengthPeaking,
        twelveWeekTransform
    ]

    // MARK: - Pre-built Templates

    static let beginnerStrength = PlanTemplate(
        name: "Beginner Strength",
        description: "Perfect for those new to strength training. Build a solid foundation with full body workouts 3x per week. Includes deload weeks for recovery.",
        durationWeeks: 8,
        workoutsPerWeek: 3,
        goal: .strength,
        split: .fullBody,
        weekStructure: [
            .init(weekNumber: 1, weekType: .regular, notes: "Start light, focus on form"),
            .init(weekNumber: 2, weekType: .regular, notes: "Small weight increases"),
            .init(weekNumber: 3, weekType: .regular, notes: "Building momentum"),
            .init(weekNumber: 4, weekType: .deload, notes: "Recovery week - reduce weights 40%"),
            .init(weekNumber: 5, weekType: .regular, notes: "Fresh start with slightly heavier weights"),
            .init(weekNumber: 6, weekType: .regular, notes: "Push for PRs"),
            .init(weekNumber: 7, weekType: .regular, notes: "Final push"),
            .init(weekNumber: 8, weekType: .deload, notes: "Deload and test new maxes")
        ],
        workoutNames: ["Full Body A", "Full Body B", "Full Body C"],
        workoutExercises: [
            // Full Body A - Squat focus
            WorkoutExerciseDefinition(workoutName: "Full Body A", exercises: [
                ExerciseDefinition(name: "Barbell Squat", sets: 3, repsMin: 5, repsMax: 5, rpe: 7),
                ExerciseDefinition(name: "Bench Press", sets: 3, repsMin: 5, repsMax: 5, rpe: 7),
                ExerciseDefinition(name: "Barbell Row", sets: 3, repsMin: 5, repsMax: 8, rpe: 7),
                ExerciseDefinition(name: "Dumbbell Shoulder Press", sets: 2, repsMin: 8, repsMax: 10, rpe: 7),
                ExerciseDefinition(name: "Plank", sets: 3, repsMin: 30, repsMax: 30, rpe: 6) // 30 seconds
            ]),
            // Full Body B - Deadlift focus
            WorkoutExerciseDefinition(workoutName: "Full Body B", exercises: [
                ExerciseDefinition(name: "Deadlift", sets: 3, repsMin: 5, repsMax: 5, rpe: 7),
                ExerciseDefinition(name: "Overhead Press", sets: 3, repsMin: 5, repsMax: 5, rpe: 7),
                ExerciseDefinition(name: "Lat Pulldown", sets: 3, repsMin: 8, repsMax: 10, rpe: 7),
                ExerciseDefinition(name: "Leg Press", sets: 3, repsMin: 8, repsMax: 10, rpe: 7),
                ExerciseDefinition(name: "Dumbbell Curl", sets: 2, repsMin: 10, repsMax: 12, rpe: 7)
            ]),
            // Full Body C - Bench focus
            WorkoutExerciseDefinition(workoutName: "Full Body C", exercises: [
                ExerciseDefinition(name: "Bench Press", sets: 3, repsMin: 5, repsMax: 5, rpe: 7),
                ExerciseDefinition(name: "Barbell Squat", sets: 3, repsMin: 8, repsMax: 8, rpe: 7),
                ExerciseDefinition(name: "Dumbbell Row", sets: 3, repsMin: 8, repsMax: 10, rpe: 7),
                ExerciseDefinition(name: "Romanian Deadlift", sets: 3, repsMin: 8, repsMax: 10, rpe: 7),
                ExerciseDefinition(name: "Tricep Pushdown", sets: 2, repsMin: 10, repsMax: 12, rpe: 7)
            ])
        ]
    )
    
    static let hypertrophyBlock = PlanTemplate(
        name: "Hypertrophy Block",
        description: "6-week muscle building focus with Upper/Lower split. Higher volume, moderate intensity. Perfect for adding size.",
        durationWeeks: 6,
        workoutsPerWeek: 4,
        goal: .hypertrophy,
        split: .upperLower,
        weekStructure: [
            .init(weekNumber: 1, weekType: .regular, notes: "Establish working weights"),
            .init(weekNumber: 2, weekType: .regular, notes: "Add reps where possible"),
            .init(weekNumber: 3, weekType: .regular, notes: "Peak volume week"),
            .init(weekNumber: 4, weekType: .regular, notes: "Increase weight slightly"),
            .init(weekNumber: 5, weekType: .regular, notes: "Push for rep PRs"),
            .init(weekNumber: 6, weekType: .deload, notes: "Recovery and assessment")
        ],
        workoutNames: ["Upper A", "Lower A", "Upper B", "Lower B"],
        workoutExercises: [
            // Upper A - Horizontal push focus
            WorkoutExerciseDefinition(workoutName: "Upper A", exercises: [
                ExerciseDefinition(name: "Bench Press", sets: 4, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Barbell Row", sets: 4, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Incline Dumbbell Press", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Lat Pulldown", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Lateral Raise", sets: 3, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Tricep Pushdown", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Dumbbell Curl", sets: 3, repsMin: 10, repsMax: 12, rpe: 8)
            ]),
            // Lower A - Quad focus
            WorkoutExerciseDefinition(workoutName: "Lower A", exercises: [
                ExerciseDefinition(name: "Barbell Squat", sets: 4, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Romanian Deadlift", sets: 4, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Leg Press", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Curl", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Extension", sets: 3, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Standing Calf Raise", sets: 4, repsMin: 12, repsMax: 15, rpe: 8)
            ]),
            // Upper B - Vertical push focus
            WorkoutExerciseDefinition(workoutName: "Upper B", exercises: [
                ExerciseDefinition(name: "Overhead Press", sets: 4, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Pull-ups", sets: 4, repsMin: 6, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Dumbbell Bench Press", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Cable Row", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Face Pull", sets: 3, repsMin: 15, repsMax: 20, rpe: 7),
                ExerciseDefinition(name: "Overhead Tricep Extension", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Barbell Curl", sets: 3, repsMin: 10, repsMax: 12, rpe: 8)
            ]),
            // Lower B - Hip hinge focus
            WorkoutExerciseDefinition(workoutName: "Lower B", exercises: [
                ExerciseDefinition(name: "Deadlift", sets: 4, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Bulgarian Split Squat", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Curl", sets: 4, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Hack Squat", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Extension", sets: 3, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Seated Calf Raise", sets: 4, repsMin: 12, repsMax: 15, rpe: 8)
            ])
        ]
    )
    
    static let pplPowerBuilder = PlanTemplate(
        name: "PPL Power Builder",
        description: "8-week Push/Pull/Legs program balancing strength and size. 6 days per week with strategic deloads.",
        durationWeeks: 8,
        workoutsPerWeek: 6,
        goal: .both,
        split: .ppl,
        weekStructure: [
            .init(weekNumber: 1, weekType: .regular, notes: "Week 1: Establish baselines"),
            .init(weekNumber: 2, weekType: .regular, notes: "Week 2: Progressive overload"),
            .init(weekNumber: 3, weekType: .regular, notes: "Week 3: Intensity focus"),
            .init(weekNumber: 4, weekType: .deload, notes: "Deload: 60% weights, 50% sets"),
            .init(weekNumber: 5, weekType: .regular, notes: "Week 5: Fresh restart"),
            .init(weekNumber: 6, weekType: .regular, notes: "Week 6: Volume peak"),
            .init(weekNumber: 7, weekType: .peak, notes: "Week 7: Peak intensity"),
            .init(weekNumber: 8, weekType: .deload, notes: "Final deload and assessment")
        ],
        workoutNames: ["Push", "Pull", "Legs", "Push", "Pull", "Legs"],
        workoutExercises: [
            // Push A - Strength focus (Chest primary)
            WorkoutExerciseDefinition(workoutName: "Push", exercises: [
                ExerciseDefinition(name: "Bench Press", sets: 4, repsMin: 4, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Overhead Press", sets: 3, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Incline Dumbbell Press", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Dips", sets: 3, repsMin: 8, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Lateral Raise", sets: 4, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Tricep Pushdown", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Overhead Tricep Extension", sets: 3, repsMin: 10, repsMax: 12, rpe: 8)
            ]),
            // Pull A - Strength focus (Back primary)
            WorkoutExerciseDefinition(workoutName: "Pull", exercises: [
                ExerciseDefinition(name: "Deadlift", sets: 4, repsMin: 4, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Barbell Row", sets: 4, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Pull-ups", sets: 3, repsMin: 6, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Cable Row", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Face Pull", sets: 3, repsMin: 15, repsMax: 20, rpe: 7),
                ExerciseDefinition(name: "Barbell Curl", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Dumbbell Curl", sets: 3, repsMin: 10, repsMax: 12, rpe: 8)
            ]),
            // Legs A - Strength focus (Quad primary)
            WorkoutExerciseDefinition(workoutName: "Legs", exercises: [
                ExerciseDefinition(name: "Barbell Squat", sets: 4, repsMin: 4, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Romanian Deadlift", sets: 4, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Leg Press", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Curl", sets: 4, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Extension", sets: 3, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Standing Calf Raise", sets: 4, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Seated Calf Raise", sets: 3, repsMin: 15, repsMax: 20, rpe: 8)
            ])
        ]
    )
    
    static let strengthPeaking = PlanTemplate(
        name: "Strength Peaking",
        description: "4-week peaking program for testing maxes. Reduced volume, increasing intensity leading to test day.",
        durationWeeks: 4,
        workoutsPerWeek: 4,
        goal: .strength,
        split: .upperLower,
        weekStructure: [
            .init(weekNumber: 1, weekType: .regular, notes: "Moderate volume, building intensity"),
            .init(weekNumber: 2, weekType: .regular, notes: "Reducing volume, higher weights"),
            .init(weekNumber: 3, weekType: .peak, notes: "Peak week - heavy singles and doubles"),
            .init(weekNumber: 4, weekType: .test, notes: "TEST WEEK - hit your new maxes!")
        ],
        workoutNames: ["Upper A", "Lower A", "Upper B", "Lower B"],
        workoutExercises: [
            // Upper A - Bench primary
            WorkoutExerciseDefinition(workoutName: "Upper A", exercises: [
                ExerciseDefinition(name: "Bench Press", sets: 5, repsMin: 3, repsMax: 5, rpe: 9),
                ExerciseDefinition(name: "Barbell Row", sets: 4, repsMin: 5, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Close Grip Bench Press", sets: 3, repsMin: 5, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Chin-ups", sets: 3, repsMin: 5, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Face Pull", sets: 3, repsMin: 12, repsMax: 15, rpe: 7)
            ]),
            // Lower A - Squat primary
            WorkoutExerciseDefinition(workoutName: "Lower A", exercises: [
                ExerciseDefinition(name: "Barbell Squat", sets: 5, repsMin: 3, repsMax: 5, rpe: 9),
                ExerciseDefinition(name: "Romanian Deadlift", sets: 3, repsMin: 5, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Leg Press", sets: 3, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Leg Curl", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Standing Calf Raise", sets: 3, repsMin: 10, repsMax: 12, rpe: 8)
            ]),
            // Upper B - OHP primary
            WorkoutExerciseDefinition(workoutName: "Upper B", exercises: [
                ExerciseDefinition(name: "Overhead Press", sets: 5, repsMin: 3, repsMax: 5, rpe: 9),
                ExerciseDefinition(name: "Pull-ups", sets: 4, repsMin: 5, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Incline Bench Press", sets: 3, repsMin: 5, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Dumbbell Row", sets: 3, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Lateral Raise", sets: 3, repsMin: 10, repsMax: 12, rpe: 7)
            ]),
            // Lower B - Deadlift primary
            WorkoutExerciseDefinition(workoutName: "Lower B", exercises: [
                ExerciseDefinition(name: "Deadlift", sets: 5, repsMin: 2, repsMax: 4, rpe: 9),
                ExerciseDefinition(name: "Front Squat", sets: 3, repsMin: 4, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Bulgarian Split Squat", sets: 3, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Leg Curl", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Plank", sets: 3, repsMin: 45, repsMax: 60, rpe: 7) // seconds
            ])
        ]
    )
    
    static let twelveWeekTransform = PlanTemplate(
        name: "12-Week Transform",
        description: "Complete transformation program with 3 phases: Hypertrophy (weeks 1-4), Strength (weeks 5-8), Peak (weeks 9-12).",
        durationWeeks: 12,
        workoutsPerWeek: 4,
        goal: .both,
        split: .upperLower,
        weekStructure: [
            // Hypertrophy Phase
            .init(weekNumber: 1, weekType: .regular, notes: "Phase 1: Hypertrophy - Higher reps (8-12)"),
            .init(weekNumber: 2, weekType: .regular, notes: "Build volume"),
            .init(weekNumber: 3, weekType: .regular, notes: "Peak hypertrophy volume"),
            .init(weekNumber: 4, weekType: .deload, notes: "Deload before strength phase"),
            // Strength Phase
            .init(weekNumber: 5, weekType: .regular, notes: "Phase 2: Strength - Lower reps (4-6)"),
            .init(weekNumber: 6, weekType: .regular, notes: "Building strength"),
            .init(weekNumber: 7, weekType: .regular, notes: "Heavy week"),
            .init(weekNumber: 8, weekType: .deload, notes: "Deload before peak phase"),
            // Peak Phase
            .init(weekNumber: 9, weekType: .regular, notes: "Phase 3: Peak - Very low reps (1-3)"),
            .init(weekNumber: 10, weekType: .peak, notes: "Intensity peak"),
            .init(weekNumber: 11, weekType: .peak, notes: "Final heavy week"),
            .init(weekNumber: 12, weekType: .test, notes: "TEST YOUR MAXES!")
        ],
        workoutNames: ["Upper A", "Lower A", "Upper B", "Lower B"],
        workoutExercises: [
            // Upper A - Horizontal push primary
            WorkoutExerciseDefinition(workoutName: "Upper A", exercises: [
                ExerciseDefinition(name: "Bench Press", sets: 4, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Barbell Row", sets: 4, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Incline Dumbbell Press", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Lat Pulldown", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Lateral Raise", sets: 3, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Tricep Pushdown", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Barbell Curl", sets: 3, repsMin: 10, repsMax: 12, rpe: 8)
            ]),
            // Lower A - Squat primary
            WorkoutExerciseDefinition(workoutName: "Lower A", exercises: [
                ExerciseDefinition(name: "Barbell Squat", sets: 4, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Romanian Deadlift", sets: 4, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Leg Press", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Curl", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Leg Extension", sets: 3, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Standing Calf Raise", sets: 4, repsMin: 12, repsMax: 15, rpe: 8)
            ]),
            // Upper B - Vertical push primary
            WorkoutExerciseDefinition(workoutName: "Upper B", exercises: [
                ExerciseDefinition(name: "Overhead Press", sets: 4, repsMin: 6, repsMax: 8, rpe: 8),
                ExerciseDefinition(name: "Pull-ups", sets: 4, repsMin: 6, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Dumbbell Bench Press", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Cable Row", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Face Pull", sets: 3, repsMin: 15, repsMax: 20, rpe: 7),
                ExerciseDefinition(name: "Overhead Tricep Extension", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Dumbbell Curl", sets: 3, repsMin: 10, repsMax: 12, rpe: 8)
            ]),
            // Lower B - Deadlift primary
            WorkoutExerciseDefinition(workoutName: "Lower B", exercises: [
                ExerciseDefinition(name: "Deadlift", sets: 4, repsMin: 5, repsMax: 6, rpe: 8),
                ExerciseDefinition(name: "Bulgarian Split Squat", sets: 3, repsMin: 8, repsMax: 10, rpe: 8),
                ExerciseDefinition(name: "Leg Curl", sets: 4, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Hack Squat", sets: 3, repsMin: 10, repsMax: 12, rpe: 8),
                ExerciseDefinition(name: "Seated Calf Raise", sets: 4, repsMin: 12, repsMax: 15, rpe: 8),
                ExerciseDefinition(name: "Cable Crunch", sets: 3, repsMin: 12, repsMax: 15, rpe: 8)
            ])
        ]
    )
    
    // MARK: - Create Plan from Template

    /// Creates a WorkoutPlan from a template, creating workout templates with exercises
    static func createPlan(
        from template: PlanTemplate,
        exercises: [Exercise],
        in context: ModelContext
    ) -> WorkoutPlan {
        let plan = WorkoutPlan(
            name: template.name,
            planDescription: template.description,
            durationWeeks: template.durationWeeks,
            workoutsPerWeek: template.workoutsPerWeek,
            goal: template.goal
        )

        // Create workout templates from exercise definitions
        var workoutTemplates: [WorkoutTemplate] = []
        let uniqueWorkoutNames = Array(Set(template.workoutNames))

        for (index, workoutName) in uniqueWorkoutNames.enumerated() {
            let exerciseDefs = template.getExercises(for: workoutName)

            let workoutTemplate = WorkoutTemplate(
                name: workoutName,
                dayNumber: index + 1,
                targetDuration: 60
            )

            // Insert template first so relationships work
            context.insert(workoutTemplate)

            // Create exercise templates
            for (exerciseIndex, exerciseDef) in exerciseDefs.enumerated() {
                // Find matching exercise using fuzzy matching
                let matchingExercise = ExerciseMatcher.findBestMatch(
                    name: exerciseDef.name,
                    in: exercises
                )

                // Create prescription based on goal
                let prescription = Prescription(
                    progressionType: template.goal == .strength ? .topSetBackoff : .doubleProgression,
                    topSetRepsMin: exerciseDef.repsMin,
                    topSetRepsMax: exerciseDef.repsMax,
                    topSetRPECap: exerciseDef.rpe,
                    backoffSets: template.goal == .strength ? 2 : 0,
                    backoffRepsMin: exerciseDef.repsMin + 2,
                    backoffRepsMax: exerciseDef.repsMax + 2,
                    backoffLoadDropPercent: 10,
                    workingSets: exerciseDef.sets
                )

                let exerciseTemplate = ExerciseTemplate(
                    exercise: matchingExercise,
                    orderIndex: exerciseIndex,
                    isOptional: exerciseDef.isOptional,
                    prescription: prescription
                )

                // Set inverse relationship
                exerciseTemplate.template = workoutTemplate
                workoutTemplate.exercises.append(exerciseTemplate)
                context.insert(exerciseTemplate)

                if matchingExercise == nil {
                    print("⚠️ PlanTemplateLibrary: Exercise not found: \(exerciseDef.name)")
                }
            }

            workoutTemplates.append(workoutTemplate)
        }

        // Create weeks and assign templates
        var planWeeks: [PlanWeek] = []
        for weekDef in template.weekStructure {
            let week = PlanWeek(
                weekNumber: weekDef.weekNumber,
                weekType: weekDef.weekType,
                notes: weekDef.notes
            )

            // Assign all workout templates to this week
            week.templates = workoutTemplates
            week.plan = plan
            context.insert(week)
            planWeeks.append(week)
        }

        plan.weeks = planWeeks
        context.insert(plan)

        return plan
    }

    /// Legacy method for backwards compatibility - creates plan without exercises
    static func createPlan(
        from template: PlanTemplate,
        existingTemplates: [WorkoutTemplate],
        in context: ModelContext
    ) -> WorkoutPlan {
        let plan = WorkoutPlan(
            name: template.name,
            planDescription: template.description,
            durationWeeks: template.durationWeeks,
            workoutsPerWeek: template.workoutsPerWeek,
            goal: template.goal
        )

        // Create weeks
        var planWeeks: [PlanWeek] = []
        for weekDef in template.weekStructure {
            let week = PlanWeek(
                weekNumber: weekDef.weekNumber,
                weekType: weekDef.weekType,
                notes: weekDef.notes
            )

            // Try to match existing templates by name pattern
            let matchingTemplates = existingTemplates.filter { existingTemplate in
                template.workoutNames.contains { workoutName in
                    existingTemplate.name.lowercased().contains(workoutName.lowercased())
                }
            }

            if !matchingTemplates.isEmpty {
                week.templates = matchingTemplates
            }

            week.plan = plan
            planWeeks.append(week)
        }

        plan.weeks = planWeeks
        return plan
    }
}

// MARK: - Supporting Types

struct PlanTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let durationWeeks: Int
    let workoutsPerWeek: Int
    let goal: Goal
    let split: Split
    let weekStructure: [WeekDefinition]
    let workoutNames: [String]
    let workoutExercises: [WorkoutExerciseDefinition]

    init(
        name: String,
        description: String,
        durationWeeks: Int,
        workoutsPerWeek: Int,
        goal: Goal,
        split: Split,
        weekStructure: [WeekDefinition],
        workoutNames: [String],
        workoutExercises: [WorkoutExerciseDefinition] = []
    ) {
        self.name = name
        self.description = description
        self.durationWeeks = durationWeeks
        self.workoutsPerWeek = workoutsPerWeek
        self.goal = goal
        self.split = split
        self.weekStructure = weekStructure
        self.workoutNames = workoutNames
        self.workoutExercises = workoutExercises
    }

    var durationText: String {
        "\(durationWeeks) weeks"
    }

    var scheduleText: String {
        "\(workoutsPerWeek)x per week"
    }

    /// Get exercise definitions for a specific workout name
    func getExercises(for workoutName: String) -> [ExerciseDefinition] {
        workoutExercises.first { $0.workoutName == workoutName }?.exercises ?? []
    }
}

struct WeekDefinition {
    let weekNumber: Int
    let weekType: WeekType
    let notes: String?

    init(weekNumber: Int, weekType: WeekType, notes: String? = nil) {
        self.weekNumber = weekNumber
        self.weekType = weekType
        self.notes = notes
    }
}

/// Defines exercises for a specific workout within a plan template
struct WorkoutExerciseDefinition {
    let workoutName: String
    let exercises: [ExerciseDefinition]
}

/// Defines a single exercise with its prescription
struct ExerciseDefinition {
    let name: String
    let sets: Int
    let repsMin: Int
    let repsMax: Int
    let rpe: Double
    let isOptional: Bool

    init(name: String, sets: Int, repsMin: Int, repsMax: Int, rpe: Double, isOptional: Bool = false) {
        self.name = name
        self.sets = sets
        self.repsMin = repsMin
        self.repsMax = repsMax
        self.rpe = rpe
        self.isOptional = isOptional
    }
}
