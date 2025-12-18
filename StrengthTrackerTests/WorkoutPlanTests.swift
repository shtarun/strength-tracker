import XCTest
@testable import StrengthTracker

// MARK: - WeekType Tests

final class WeekTypeTests: XCTestCase {
    
    func testWeekType_RegularDefaults() {
        let weekType = WeekType.regular
        
        XCTAssertEqual(weekType.intensityModifier, 1.0)
        XCTAssertEqual(weekType.volumeModifier, 1.0)
        XCTAssertEqual(weekType.rpeCap, 10.0)
        XCTAssertEqual(weekType.icon, "calendar")
    }
    
    func testWeekType_DeloadModifiers() {
        let weekType = WeekType.deload
        
        XCTAssertEqual(weekType.intensityModifier, 0.6)
        XCTAssertEqual(weekType.volumeModifier, 0.5)
        XCTAssertEqual(weekType.rpeCap, 7.0)
        XCTAssertEqual(weekType.icon, "bed.double.fill")
    }
    
    func testWeekType_PeakModifiers() {
        let weekType = WeekType.peak
        
        XCTAssertEqual(weekType.intensityModifier, 1.05)
        XCTAssertEqual(weekType.volumeModifier, 0.7)
        XCTAssertEqual(weekType.rpeCap, 9.5)
        XCTAssertEqual(weekType.icon, "flame.fill")
    }
    
    func testWeekType_TestModifiers() {
        let weekType = WeekType.test
        
        XCTAssertEqual(weekType.intensityModifier, 1.0)
        XCTAssertEqual(weekType.volumeModifier, 0.3)
        XCTAssertEqual(weekType.rpeCap, 10.0)
        XCTAssertEqual(weekType.icon, "trophy.fill")
    }
    
    func testWeekType_CaseIterable() {
        let allCases = WeekType.allCases
        
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.regular))
        XCTAssertTrue(allCases.contains(.deload))
        XCTAssertTrue(allCases.contains(.peak))
        XCTAssertTrue(allCases.contains(.test))
    }
    
    func testWeekType_RawValue() {
        XCTAssertEqual(WeekType.regular.rawValue, "regular")
        XCTAssertEqual(WeekType.deload.rawValue, "deload")
        XCTAssertEqual(WeekType.peak.rawValue, "peak")
        XCTAssertEqual(WeekType.test.rawValue, "test")
        
        // Test initialization from raw value
        XCTAssertEqual(WeekType(rawValue: "regular"), .regular)
        XCTAssertEqual(WeekType(rawValue: "deload"), .deload)
        XCTAssertNil(WeekType(rawValue: "invalid"))
    }
    
    func testWeekType_CoachingNotes() {
        XCTAssertFalse(WeekType.regular.coachingNotes.isEmpty)
        XCTAssertFalse(WeekType.deload.coachingNotes.isEmpty)
        XCTAssertFalse(WeekType.peak.coachingNotes.isEmpty)
        XCTAssertFalse(WeekType.test.coachingNotes.isEmpty)
    }
}

// MARK: - PlanWeek Tests

final class PlanWeekTests: XCTestCase {
    
    func testPlanWeek_Creation() {
        let week = PlanWeek(weekNumber: 1)
        
        XCTAssertEqual(week.weekNumber, 1)
        XCTAssertEqual(week.weekType, .regular)
        XCTAssertEqual(week.intensityModifier, 1.0)
        XCTAssertEqual(week.volumeModifier, 1.0)
        XCTAssertFalse(week.isCompleted)
        XCTAssertTrue(week.templates.isEmpty)
    }
    
    func testPlanWeek_CreationWithWeekType() {
        let week = PlanWeek(weekNumber: 4, weekType: .deload)
        
        XCTAssertEqual(week.weekNumber, 4)
        XCTAssertEqual(week.weekType, .deload)
        XCTAssertEqual(week.intensityModifier, 0.6)
        XCTAssertEqual(week.volumeModifier, 0.5)
    }
    
    func testPlanWeek_CustomModifiers() {
        let week = PlanWeek(
            weekNumber: 2,
            weekType: .regular,
            intensityModifier: 0.9,
            volumeModifier: 0.8
        )
        
        XCTAssertEqual(week.intensityModifier, 0.9)
        XCTAssertEqual(week.volumeModifier, 0.8)
    }
    
    func testPlanWeek_WeekLabel() {
        let week1 = PlanWeek(weekNumber: 1)
        let week5 = PlanWeek(weekNumber: 5)
        
        XCTAssertEqual(week1.weekLabel, "Week 1")
        XCTAssertEqual(week5.weekLabel, "Week 5")
    }
    
    func testPlanWeek_WorkoutCount() {
        let week = PlanWeek(weekNumber: 1)
        XCTAssertEqual(week.workoutCount, 0)
        
        // Note: Can't easily add templates without SwiftData context
        // This would be tested in integration tests
    }
    
    func testPlanWeek_AdjustedWeight() {
        let regularWeek = PlanWeek(weekNumber: 1, weekType: .regular)
        let deloadWeek = PlanWeek(weekNumber: 4, weekType: .deload)
        
        let baseWeight = 100.0
        
        XCTAssertEqual(regularWeek.adjustedWeight(baseWeight: baseWeight), 100.0)
        XCTAssertEqual(deloadWeek.adjustedWeight(baseWeight: baseWeight), 60.0, accuracy: 0.01)
    }
    
    func testPlanWeek_StatusIcon() {
        let completedWeek = PlanWeek(weekNumber: 1, isCompleted: true)
        let pendingWeek = PlanWeek(weekNumber: 2, isCompleted: false)
        
        XCTAssertEqual(completedWeek.statusIcon, "checkmark.circle.fill")
        XCTAssertEqual(pendingWeek.statusIcon, "circle")
    }
    
    func testPlanWeek_SummaryText_Empty() {
        let week = PlanWeek(weekNumber: 1)
        
        XCTAssertEqual(week.summaryText, "No workouts assigned")
    }
    
    func testPlanWeek_WeekTypeRawConversion() {
        let week = PlanWeek(weekNumber: 1, weekType: .peak)
        
        XCTAssertEqual(week.weekTypeRaw, "peak")
        XCTAssertEqual(week.weekType, .peak)
        
        // Change week type
        week.weekType = .deload
        XCTAssertEqual(week.weekTypeRaw, "deload")
        XCTAssertEqual(week.weekType, .deload)
    }
}

// MARK: - WorkoutPlan Tests

final class WorkoutPlanTests: XCTestCase {
    
    func testWorkoutPlan_Creation() {
        let plan = WorkoutPlan(name: "Test Plan")
        
        XCTAssertEqual(plan.name, "Test Plan")
        XCTAssertEqual(plan.durationWeeks, 4)
        XCTAssertEqual(plan.currentWeek, 1)
        XCTAssertFalse(plan.isActive)
        XCTAssertEqual(plan.workoutsPerWeek, 4)
        XCTAssertEqual(plan.goal, .both)
        XCTAssertTrue(plan.weeks.isEmpty)
    }
    
    func testWorkoutPlan_CreationWithAllParams() {
        let plan = WorkoutPlan(
            name: "Strength Program",
            planDescription: "8-week strength focus",
            durationWeeks: 8,
            currentWeek: 1,
            isActive: false,
            workoutsPerWeek: 4,
            goal: .strength
        )
        
        XCTAssertEqual(plan.name, "Strength Program")
        XCTAssertEqual(plan.planDescription, "8-week strength focus")
        XCTAssertEqual(plan.durationWeeks, 8)
        XCTAssertEqual(plan.goal, .strength)
    }
    
    func testWorkoutPlan_StatusText_NotStarted() {
        let plan = WorkoutPlan(name: "Test Plan", durationWeeks: 6)
        
        XCTAssertEqual(plan.statusText, "6 weeks • Not started")
    }
    
    func testWorkoutPlan_StatusText_Active() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 6,
            currentWeek: 3,
            isActive: true,
            startDate: Date()
        )
        
        XCTAssertEqual(plan.statusText, "Week 3 of 6")
    }
    
    func testWorkoutPlan_RemainingWeeks() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 8,
            currentWeek: 3
        )
        
        XCTAssertEqual(plan.remainingWeeks, 6) // 8 - 3 + 1
    }
    
    func testWorkoutPlan_ProgressPercentage_NoProgress() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 4,
            completedWorkoutsThisWeek: 0
        )
        
        XCTAssertEqual(plan.progressPercentage, 0.0, accuracy: 0.01)
    }
    
    func testWorkoutPlan_ProgressPercentage_HalfwayThroughWeek() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 4,
            completedWorkoutsThisWeek: 2,
            workoutsPerWeek: 4
        )
        
        // 2/4 workouts = 0.5 week, 0.5/4 weeks = 0.125 = 12.5%
        XCTAssertEqual(plan.progressPercentage, 0.125, accuracy: 0.01)
    }
    
    func testWorkoutPlan_IsCompleted() {
        let incompletePlan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 4
        )
        
        XCTAssertFalse(incompletePlan.isCompleted)
        
        // Create completed plan by adding completed weeks
        let completedPlan = WorkoutPlan(
            name: "Completed Plan",
            durationWeeks: 4,
            weeks: [
                PlanWeek(weekNumber: 1, isCompleted: true),
                PlanWeek(weekNumber: 2, isCompleted: true),
                PlanWeek(weekNumber: 3, isCompleted: true),
                PlanWeek(weekNumber: 4, isCompleted: true)
            ]
        )
        
        XCTAssertTrue(completedPlan.isCompleted)
    }
    
    func testWorkoutPlan_CompletedWeeks() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 6,
            weeks: [
                PlanWeek(weekNumber: 1, isCompleted: true),
                PlanWeek(weekNumber: 2, isCompleted: true),
                PlanWeek(weekNumber: 3, isCompleted: false),
                PlanWeek(weekNumber: 4, isCompleted: false),
                PlanWeek(weekNumber: 5, isCompleted: false),
                PlanWeek(weekNumber: 6, isCompleted: false)
            ]
        )
        
        XCTAssertEqual(plan.completedWeeks, 2)
    }
    
    func testWorkoutPlan_SortedWeeks() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 3,
            weeks: [
                PlanWeek(weekNumber: 3),
                PlanWeek(weekNumber: 1),
                PlanWeek(weekNumber: 2)
            ]
        )
        
        let sorted = plan.sortedWeeks
        XCTAssertEqual(sorted[0].weekNumber, 1)
        XCTAssertEqual(sorted[1].weekNumber, 2)
        XCTAssertEqual(sorted[2].weekNumber, 3)
    }
    
    func testWorkoutPlan_CurrentPlanWeek() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 4,
            currentWeek: 2,
            weeks: [
                PlanWeek(weekNumber: 1),
                PlanWeek(weekNumber: 2, weekType: .regular),
                PlanWeek(weekNumber: 3),
                PlanWeek(weekNumber: 4, weekType: .deload)
            ]
        )
        
        let currentWeek = plan.currentPlanWeek
        XCTAssertNotNil(currentWeek)
        XCTAssertEqual(currentWeek?.weekNumber, 2)
    }
    
    func testWorkoutPlan_EstimatedEndDate() {
        let startDate = Date()
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 8,
            startDate: startDate
        )
        
        let endDate = plan.estimatedEndDate
        XCTAssertNotNil(endDate)
        
        let calendar = Calendar.current
        let weeks = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate!).weekOfYear
        XCTAssertEqual(weeks, 8)
    }
    
    func testWorkoutPlan_RecordCompletedWorkout_NotActive() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            isActive: false,
            completedWorkoutsThisWeek: 0
        )
        
        plan.recordCompletedWorkout()
        
        // Should not increment when plan is not active
        XCTAssertEqual(plan.completedWorkoutsThisWeek, 0)
    }
    
    func testWorkoutPlan_RecordCompletedWorkout_Active() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            isActive: true,
            completedWorkoutsThisWeek: 1,
            workoutsPerWeek: 4
        )
        
        plan.recordCompletedWorkout()
        
        XCTAssertEqual(plan.completedWorkoutsThisWeek, 2)
    }
    
    func testWorkoutPlan_AdvanceWeek_WhenComplete() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 4,
            currentWeek: 1,
            isActive: true,
            completedWorkoutsThisWeek: 3,
            workoutsPerWeek: 4,
            weeks: [
                PlanWeek(weekNumber: 1),
                PlanWeek(weekNumber: 2),
                PlanWeek(weekNumber: 3),
                PlanWeek(weekNumber: 4)
            ]
        )
        
        // Complete the week
        plan.recordCompletedWorkout()
        
        // Should advance to week 2
        XCTAssertEqual(plan.currentWeek, 2)
        XCTAssertEqual(plan.completedWorkoutsThisWeek, 0)
    }
    
    func testWorkoutPlan_DoesNotAdvance_WhenIncomplete() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 4,
            currentWeek: 1,
            isActive: true,
            completedWorkoutsThisWeek: 1,
            workoutsPerWeek: 4
        )
        
        plan.advanceWeekIfNeeded()
        
        // Should stay on week 1
        XCTAssertEqual(plan.currentWeek, 1)
    }
    
    func testWorkoutPlan_CompletesAtEnd() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 2,
            currentWeek: 2,
            isActive: true,
            completedWorkoutsThisWeek: 3,
            workoutsPerWeek: 4,
            weeks: [
                PlanWeek(weekNumber: 1, isCompleted: true),
                PlanWeek(weekNumber: 2)
            ]
        )
        
        // Complete last workout of last week
        plan.recordCompletedWorkout()
        
        // Plan should be deactivated (completed)
        XCTAssertFalse(plan.isActive)
    }
}

// MARK: - PlanTemplateLibrary Tests

final class PlanTemplateLibraryTests: XCTestCase {
    
    func testPlanTemplateLibrary_AllTemplates() {
        let templates = PlanTemplateLibrary.templates
        
        XCTAssertGreaterThanOrEqual(templates.count, 5)
    }
    
    func testPlanTemplateLibrary_BeginnerStrength() {
        let template = PlanTemplateLibrary.beginnerStrength
        
        XCTAssertNotNil(template.id)
        XCTAssertEqual(template.name, "Beginner Strength")
        XCTAssertEqual(template.durationWeeks, 8)
        XCTAssertEqual(template.workoutsPerWeek, 3)
        XCTAssertEqual(template.goal, .strength)
        XCTAssertFalse(template.weekStructure.isEmpty)
    }
    
    func testPlanTemplateLibrary_HypertrophyBlock() {
        let template = PlanTemplateLibrary.hypertrophyBlock
        
        XCTAssertNotNil(template.id)
        XCTAssertEqual(template.name, "Hypertrophy Block")
        XCTAssertEqual(template.durationWeeks, 6)
        XCTAssertEqual(template.workoutsPerWeek, 4)
        XCTAssertEqual(template.goal, .hypertrophy)
    }
    
    func testPlanTemplateLibrary_TemplateHasWeekStructure() {
        let template = PlanTemplateLibrary.beginnerStrength
        
        XCTAssertEqual(template.weekStructure.count, template.durationWeeks)
        
        // Check that weeks are numbered correctly
        for (index, week) in template.weekStructure.enumerated() {
            XCTAssertEqual(week.weekNumber, index + 1)
        }
    }
    
    func testPlanTemplateLibrary_TemplateHasWorkoutNames() {
        for template in PlanTemplateLibrary.templates {
            XCTAssertFalse(template.workoutNames.isEmpty, "Template \(template.name) should have workout names")
        }
    }
    
    func testPlanTemplateLibrary_DurationText() {
        let template = PlanTemplateLibrary.beginnerStrength
        
        XCTAssertEqual(template.durationText, "8 weeks")
    }
    
    func testPlanTemplateLibrary_ScheduleText() {
        let template = PlanTemplateLibrary.beginnerStrength
        
        XCTAssertEqual(template.scheduleText, "3x per week")
    }
    
    func testPlanTemplateLibrary_HasDeloadWeeks() {
        let template = PlanTemplateLibrary.beginnerStrength

        let hasDeload = template.weekStructure.contains { $0.weekType == .deload }
        XCTAssertTrue(hasDeload, "Beginner strength should include deload weeks")
    }

    func testPlanTemplateLibrary_FilterByGoal() {
        let allTemplates = PlanTemplateLibrary.templates
        let strengthTemplates = allTemplates.filter { $0.goal == .strength }
        let hypertrophyTemplates = allTemplates.filter { $0.goal == .hypertrophy }

        XCTAssertFalse(strengthTemplates.isEmpty)
        XCTAssertFalse(hypertrophyTemplates.isEmpty)

        for template in strengthTemplates {
            XCTAssertEqual(template.goal, .strength)
        }
    }

    // MARK: - Exercise Definitions Tests

    func testPlanTemplateLibrary_AllTemplatesHaveExercises() {
        for template in PlanTemplateLibrary.templates {
            XCTAssertFalse(
                template.workoutExercises.isEmpty,
                "Template \(template.name) should have exercise definitions"
            )
        }
    }

    func testPlanTemplateLibrary_BeginnerStrengthExercises() {
        let template = PlanTemplateLibrary.beginnerStrength

        // Should have 3 workout definitions (Full Body A, B, C)
        XCTAssertEqual(template.workoutExercises.count, 3)

        // Full Body A should have exercises
        let fullBodyA = template.getExercises(for: "Full Body A")
        XCTAssertFalse(fullBodyA.isEmpty, "Full Body A should have exercises")
        XCTAssertGreaterThanOrEqual(fullBodyA.count, 4, "Full Body A should have at least 4 exercises")

        // Verify exercise structure
        if let firstExercise = fullBodyA.first {
            XCTAssertFalse(firstExercise.name.isEmpty)
            XCTAssertGreaterThan(firstExercise.sets, 0)
            XCTAssertGreaterThan(firstExercise.repsMin, 0)
            XCTAssertGreaterThanOrEqual(firstExercise.repsMax, firstExercise.repsMin)
            XCTAssertGreaterThan(firstExercise.rpe, 0)
        }
    }

    func testPlanTemplateLibrary_HypertrophyBlockExercises() {
        let template = PlanTemplateLibrary.hypertrophyBlock

        // Should have 4 workout definitions (Upper A, Lower A, Upper B, Lower B)
        XCTAssertEqual(template.workoutExercises.count, 4)

        // Upper A should have more exercises (hypertrophy = higher volume)
        let upperA = template.getExercises(for: "Upper A")
        XCTAssertGreaterThanOrEqual(upperA.count, 5, "Upper A should have at least 5 exercises for hypertrophy")

        // Verify higher rep ranges for hypertrophy
        for exercise in upperA {
            XCTAssertGreaterThanOrEqual(exercise.repsMax, 8, "Hypertrophy exercises should have higher rep ranges")
        }
    }

    func testPlanTemplateLibrary_PPLPowerBuilderExercises() {
        let template = PlanTemplateLibrary.pplPowerBuilder

        // Should have 3 workout definitions (Push, Pull, Legs)
        XCTAssertEqual(template.workoutExercises.count, 3)

        // Verify each day has exercises
        XCTAssertFalse(template.getExercises(for: "Push").isEmpty)
        XCTAssertFalse(template.getExercises(for: "Pull").isEmpty)
        XCTAssertFalse(template.getExercises(for: "Legs").isEmpty)
    }

    func testPlanTemplateLibrary_StrengthPeakingExercises() {
        let template = PlanTemplateLibrary.strengthPeaking

        // Should have 4 workout definitions
        XCTAssertEqual(template.workoutExercises.count, 4)

        // Verify lower rep ranges for strength
        let upperA = template.getExercises(for: "Upper A")
        XCTAssertFalse(upperA.isEmpty)

        // First exercise should be the main lift with low reps
        if let mainLift = upperA.first {
            XCTAssertLessThanOrEqual(mainLift.repsMax, 6, "Strength exercises should have lower rep ranges")
            XCTAssertGreaterThanOrEqual(mainLift.rpe, 8, "Strength exercises should have higher RPE")
        }
    }

    func testPlanTemplateLibrary_TwelveWeekTransformExercises() {
        let template = PlanTemplateLibrary.twelveWeekTransform

        // Should have 4 workout definitions
        XCTAssertEqual(template.workoutExercises.count, 4)

        // Verify each day has exercises
        for workoutDef in template.workoutExercises {
            XCTAssertFalse(
                workoutDef.exercises.isEmpty,
                "\(workoutDef.workoutName) should have exercises"
            )
        }
    }

    func testPlanTemplateLibrary_GetExercisesForNonexistentWorkout() {
        let template = PlanTemplateLibrary.beginnerStrength

        let exercises = template.getExercises(for: "Nonexistent Workout")
        XCTAssertTrue(exercises.isEmpty, "Should return empty array for nonexistent workout")
    }

    func testExerciseDefinition_DefaultIsOptional() {
        let exercise = ExerciseDefinition(
            name: "Bench Press",
            sets: 3,
            repsMin: 5,
            repsMax: 5,
            rpe: 8
        )

        XCTAssertFalse(exercise.isOptional, "Exercises should not be optional by default")
    }

    func testExerciseDefinition_OptionalExercise() {
        let exercise = ExerciseDefinition(
            name: "Calf Raise",
            sets: 3,
            repsMin: 12,
            repsMax: 15,
            rpe: 7,
            isOptional: true
        )

        XCTAssertTrue(exercise.isOptional)
    }

    func testWorkoutExerciseDefinition_Structure() {
        let workoutDef = WorkoutExerciseDefinition(
            workoutName: "Test Workout",
            exercises: [
                ExerciseDefinition(name: "Squat", sets: 3, repsMin: 5, repsMax: 5, rpe: 8),
                ExerciseDefinition(name: "Bench Press", sets: 3, repsMin: 5, repsMax: 5, rpe: 8)
            ]
        )

        XCTAssertEqual(workoutDef.workoutName, "Test Workout")
        XCTAssertEqual(workoutDef.exercises.count, 2)
    }

    func testPlanTemplateLibrary_ExerciseNamesMatchLibrary() {
        // Get all unique exercise names from templates
        var exerciseNames: Set<String> = []
        for template in PlanTemplateLibrary.templates {
            for workoutDef in template.workoutExercises {
                for exercise in workoutDef.exercises {
                    exerciseNames.insert(exercise.name)
                }
            }
        }

        // Verify we have exercise names
        XCTAssertFalse(exerciseNames.isEmpty, "Should have exercise names from templates")

        // Common exercises that should be present
        let expectedExercises = [
            "Bench Press",
            "Barbell Squat",
            "Deadlift",
            "Barbell Row",
            "Overhead Press"
        ]

        for name in expectedExercises {
            XCTAssertTrue(
                exerciseNames.contains(name),
                "Templates should include \(name)"
            )
        }
    }

    func testPlanTemplateLibrary_ValidRepRanges() {
        for template in PlanTemplateLibrary.templates {
            for workoutDef in template.workoutExercises {
                for exercise in workoutDef.exercises {
                    XCTAssertGreaterThan(
                        exercise.sets, 0,
                        "\(exercise.name) in \(template.name) should have positive sets"
                    )
                    XCTAssertGreaterThan(
                        exercise.repsMin, 0,
                        "\(exercise.name) in \(template.name) should have positive repsMin"
                    )
                    XCTAssertGreaterThanOrEqual(
                        exercise.repsMax, exercise.repsMin,
                        "\(exercise.name) in \(template.name) should have repsMax >= repsMin"
                    )
                    XCTAssertGreaterThan(
                        exercise.rpe, 0,
                        "\(exercise.name) in \(template.name) should have positive RPE"
                    )
                    XCTAssertLessThanOrEqual(
                        exercise.rpe, 10,
                        "\(exercise.name) in \(template.name) should have RPE <= 10"
                    )
                }
            }
        }
    }
}

// MARK: - PlanProgressService Tests (using shared instance)

final class PlanProgressServiceTests: XCTestCase {
    
    func testPlanWeek_AdjustedWeight_RegularWeek() {
        let regularWeek = PlanWeek(weekNumber: 1, weekType: .regular)
        let baseWeight = 100.0
        
        let adjusted = regularWeek.adjustedWeight(baseWeight: baseWeight)
        
        XCTAssertEqual(adjusted, 100.0)
    }
    
    func testPlanWeek_AdjustedWeight_DeloadWeek() {
        let deloadWeek = PlanWeek(weekNumber: 4, weekType: .deload)
        let baseWeight = 100.0
        
        let adjusted = deloadWeek.adjustedWeight(baseWeight: baseWeight)
        
        XCTAssertEqual(adjusted, 60.0, accuracy: 0.01)
    }
    
    func testPlanWeek_AdjustedWeight_PeakWeek() {
        let peakWeek = PlanWeek(weekNumber: 3, weekType: .peak)
        let baseWeight = 100.0
        
        let adjusted = peakWeek.adjustedWeight(baseWeight: baseWeight)
        
        XCTAssertEqual(adjusted, 105.0, accuracy: 0.01)
    }
    
    func testPlanWeek_ApplyModifiersToPrescription_DeloadWeek() {
        let deloadWeek = PlanWeek(weekNumber: 4, weekType: .deload)
        
        let prescription = Prescription(
            progressionType: .topSetBackoff,
            topSetRepsMin: 5,
            topSetRepsMax: 5,
            topSetRPECap: 8.5,
            backoffSets: 4,
            backoffRepsMin: 5,
            backoffRepsMax: 5,
            backoffLoadDropPercent: 0.1,
            workingSets: 3
        )
        
        let adjusted = deloadWeek.applyModifiers(to: prescription)
        
        // RPE should be capped at 7.0 for deload
        XCTAssertEqual(adjusted.topSetRPECap, 7.0)
        // Volume should be reduced
        XCTAssertLessThan(adjusted.backoffSets, 4)
    }
}

// MARK: - LLM Plan Generation Types Tests

final class LLMPlanGenerationTypesTests: XCTestCase {
    
    func testGeneratePlanRequest_Encoding() throws {
        let request = GeneratePlanRequest(
            goal: .strength,
            durationWeeks: 8,
            daysPerWeek: 4,
            split: .upperLower,
            equipment: [.barbell, .dumbbell, .bench],
            includeDeloads: true,
            focusAreas: [.chest, .lats]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        XCTAssertNotNil(data)
        
        // Verify it can be decoded
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GeneratePlanRequest.self, from: data)
        
        XCTAssertEqual(decoded.goal, .strength)
        XCTAssertEqual(decoded.durationWeeks, 8)
        XCTAssertEqual(decoded.daysPerWeek, 4)
        XCTAssertTrue(decoded.includeDeloads)
    }
    
    func testGeneratedPlanResponse_Decoding() throws {
        let json = """
        {
            "planName": "8-Week Strength Builder",
            "description": "A progressive strength program",
            "weeks": [
                {
                    "weekNumber": 1,
                    "weekType": "regular",
                    "workouts": [
                        {
                            "dayNumber": 1,
                            "name": "Upper A",
                            "exercises": [
                                {
                                    "name": "Bench Press",
                                    "sets": 4,
                                    "reps": "5",
                                    "notes": "Focus on form"
                                }
                            ],
                            "targetDuration": 60
                        }
                    ],
                    "weekNotes": "Start light"
                }
            ],
            "coachingNotes": "Progressive overload each week"
        }
        """
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(GeneratedPlanResponse.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(response.planName, "8-Week Strength Builder")
        XCTAssertEqual(response.weeks.count, 1)
        XCTAssertEqual(response.weeks[0].weekNumber, 1)
        XCTAssertEqual(response.weeks[0].weekType, "regular")
        XCTAssertEqual(response.weeks[0].workouts.count, 1)
        XCTAssertEqual(response.weeks[0].workouts[0].exercises.count, 1)
    }
    
    func testGeneratedWeek_AllWeekTypes() throws {
        let weekTypes = ["regular", "deload", "peak", "test"]
        
        for weekType in weekTypes {
            let json = """
            {
                "weekNumber": 1,
                "weekType": "\(weekType)",
                "workouts": [],
                "weekNotes": null
            }
            """
            
            let decoder = JSONDecoder()
            let week = try decoder.decode(GeneratedWeek.self, from: json.data(using: .utf8)!)
            
            XCTAssertEqual(week.weekType, weekType)
        }
    }
}

// MARK: - Integration Style Tests

final class WorkoutPlanIntegrationTests: XCTestCase {
    
    func testCreateCompletePlan() {
        // Create a plan with multiple weeks
        let plan = WorkoutPlan(
            name: "8-Week Strength Program",
            planDescription: "Progressive strength building program",
            durationWeeks: 8,
            workoutsPerWeek: 4,
            goal: .strength
        )
        
        // Add weeks with appropriate types
        let weeks = [
            PlanWeek(weekNumber: 1, weekType: .regular),
            PlanWeek(weekNumber: 2, weekType: .regular),
            PlanWeek(weekNumber: 3, weekType: .regular),
            PlanWeek(weekNumber: 4, weekType: .deload),
            PlanWeek(weekNumber: 5, weekType: .regular),
            PlanWeek(weekNumber: 6, weekType: .regular),
            PlanWeek(weekNumber: 7, weekType: .peak),
            PlanWeek(weekNumber: 8, weekType: .test)
        ]
        
        for week in weeks {
            plan.weeks.append(week)
        }
        
        // Verify plan structure
        XCTAssertEqual(plan.weeks.count, 8)
        XCTAssertEqual(plan.sortedWeeks[3].weekType, .deload)
        XCTAssertEqual(plan.sortedWeeks[6].weekType, .peak)
        XCTAssertEqual(plan.sortedWeeks[7].weekType, .test)
    }
    
    func testPlanProgression() {
        let plan = WorkoutPlan(
            name: "Test Plan",
            durationWeeks: 2,
            currentWeek: 1,
            isActive: true,
            workoutsPerWeek: 2,
            weeks: [
                PlanWeek(weekNumber: 1),
                PlanWeek(weekNumber: 2)
            ]
        )
        
        // Complete first week
        plan.recordCompletedWorkout()
        XCTAssertEqual(plan.completedWorkoutsThisWeek, 1)
        XCTAssertEqual(plan.currentWeek, 1)
        
        plan.recordCompletedWorkout()
        XCTAssertEqual(plan.completedWorkoutsThisWeek, 0) // Reset after week advance
        XCTAssertEqual(plan.currentWeek, 2)
        
        // Complete second week
        plan.recordCompletedWorkout()
        plan.recordCompletedWorkout()
        
        // Plan should be complete
        XCTAssertFalse(plan.isActive)
    }
    
    func testWeekModifiersAcrossPlan() {
        let baseWeight = 100.0
        
        let weeks = [
            PlanWeek(weekNumber: 1, weekType: .regular),
            PlanWeek(weekNumber: 2, weekType: .regular),
            PlanWeek(weekNumber: 3, weekType: .peak),
            PlanWeek(weekNumber: 4, weekType: .deload)
        ]
        
        let expectedWeights = [100.0, 100.0, 105.0, 60.0]
        
        for (index, week) in weeks.enumerated() {
            let adjustedWeight = week.adjustedWeight(baseWeight: baseWeight)
            XCTAssertEqual(adjustedWeight, expectedWeights[index], accuracy: 0.01,
                          "Week \(index + 1) should have correct weight")
        }
    }
}
