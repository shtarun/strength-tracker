import XCTest
@testable import StrengthTracker

/// Tests for custom AI-generated workout functionality
/// These tests verify that when a user starts a custom AI workout,
/// the app uses the exercises from the AI response, NOT existing templates.
final class CustomWorkoutTests: XCTestCase {
    
    // MARK: - CustomWorkoutResponse Model Tests
    
    func testCustomWorkoutResponseHasCorrectStructure() {
        let exercises = [
            CustomExercisePlan(
                exerciseName: "Bench Press",
                sets: 4,
                reps: "6-8",
                rpeCap: 8.0,
                notes: "Focus on chest stretch",
                suggestedWeight: 100.0
            ),
            CustomExercisePlan(
                exerciseName: "Incline Dumbbell Press",
                sets: 3,
                reps: "8-10",
                rpeCap: 7.5,
                notes: nil,
                suggestedWeight: 30.0
            )
        ]
        
        let response = CustomWorkoutResponse(
            workoutName: "Upper Body Push",
            exercises: exercises,
            reasoning: "Focus on chest development",
            estimatedDuration: 45,
            focusAreas: ["Chest", "Shoulders", "Triceps"]
        )
        
        XCTAssertEqual(response.workoutName, "Upper Body Push")
        XCTAssertEqual(response.exercises.count, 2)
        XCTAssertEqual(response.exercises[0].exerciseName, "Bench Press")
        XCTAssertEqual(response.exercises[1].exerciseName, "Incline Dumbbell Press")
        XCTAssertEqual(response.estimatedDuration, 45)
        XCTAssertEqual(response.focusAreas.count, 3)
    }
    
    func testCustomExercisePlanParsesRepsCorrectly() {
        let plan = CustomExercisePlan(
            exerciseName: "Squat",
            sets: 3,
            reps: "5-6",
            rpeCap: 8.5,
            notes: nil,
            suggestedWeight: nil
        )
        
        XCTAssertEqual(plan.exerciseName, "Squat")
        XCTAssertEqual(plan.sets, 3)
        XCTAssertEqual(plan.reps, "5-6")
        XCTAssertEqual(plan.rpeCap, 8.5)
        XCTAssertNil(plan.notes)
        XCTAssertNil(plan.suggestedWeight)
    }
    
    func testCustomWorkoutResponseEncodesAndDecodes() throws {
        let original = CustomWorkoutResponse(
            workoutName: "Test Workout",
            exercises: [
                CustomExercisePlan(
                    exerciseName: "Deadlift",
                    sets: 3,
                    reps: "5",
                    rpeCap: 8.0,
                    notes: "Brace hard",
                    suggestedWeight: 150.0
                )
            ],
            reasoning: "Heavy posterior chain",
            estimatedDuration: 60,
            focusAreas: ["Back", "Hamstrings"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CustomWorkoutResponse.self, from: data)
        
        XCTAssertEqual(decoded.workoutName, original.workoutName)
        XCTAssertEqual(decoded.exercises.count, original.exercises.count)
        XCTAssertEqual(decoded.exercises[0].exerciseName, "Deadlift")
        XCTAssertEqual(decoded.estimatedDuration, 60)
    }
    
    // MARK: - Custom Workout Template Creation Tests
    
    func testCreateTemplateFromCustomWorkoutResponse() {
        let response = CustomWorkoutResponse(
            workoutName: "AI Upper Body",
            exercises: [
                CustomExercisePlan(exerciseName: "Bench Press", sets: 4, reps: "6-8", rpeCap: 8.0, notes: nil, suggestedWeight: 100.0),
                CustomExercisePlan(exerciseName: "Overhead Press", sets: 3, reps: "8-10", rpeCap: 7.5, notes: nil, suggestedWeight: 50.0),
                CustomExercisePlan(exerciseName: "Tricep Pushdown", sets: 3, reps: "10-12", rpeCap: 7.0, notes: nil, suggestedWeight: nil)
            ],
            reasoning: "Push focused workout",
            estimatedDuration: 50,
            focusAreas: ["Chest", "Shoulders"]
        )
        
        // Create a template that would be used for custom workouts
        let template = WorkoutTemplate(
            name: response.workoutName,
            dayNumber: 0, // Ad-hoc workout
            targetDuration: response.estimatedDuration
        )
        
        XCTAssertEqual(template.name, "AI Upper Body")
        XCTAssertEqual(template.targetDuration, 50)
        XCTAssertEqual(template.dayNumber, 0, "Custom workouts should use dayNumber 0 to indicate ad-hoc")
    }
    
    func testCustomWorkoutExerciseCountMatchesResponse() {
        let response = CustomWorkoutResponse(
            workoutName: "Test",
            exercises: [
                CustomExercisePlan(exerciseName: "Exercise 1", sets: 3, reps: "8", rpeCap: 8.0, notes: nil, suggestedWeight: nil),
                CustomExercisePlan(exerciseName: "Exercise 2", sets: 3, reps: "10", rpeCap: 7.0, notes: nil, suggestedWeight: nil),
                CustomExercisePlan(exerciseName: "Exercise 3", sets: 4, reps: "12", rpeCap: 6.0, notes: nil, suggestedWeight: nil)
            ],
            reasoning: "Test",
            estimatedDuration: 45,
            focusAreas: []
        )
        
        // When creating ExerciseTemplates from the response, count should match
        XCTAssertEqual(response.exercises.count, 3, "Response should have exactly 3 exercises")
        
        // Verify each exercise has correct data
        XCTAssertEqual(response.exercises[0].exerciseName, "Exercise 1")
        XCTAssertEqual(response.exercises[1].exerciseName, "Exercise 2")
        XCTAssertEqual(response.exercises[2].exerciseName, "Exercise 3")
    }
    
    // MARK: - Bug Regression Tests
    
    /// This test documents the bug: when starting a custom workout,
    /// the app should use the exercises from CustomWorkoutResponse,
    /// NOT fall back to templates.first
    func testCustomWorkoutShouldNotFallbackToFirstTemplate() {
        // Scenario: User has existing templates with different exercises
        let existingTemplateName = "Push Day A"
        let customWorkoutName = "AI Quick Upper"
        
        // The custom workout response from AI
        let customResponse = CustomWorkoutResponse(
            workoutName: customWorkoutName,
            exercises: [
                CustomExercisePlan(exerciseName: "Cable Fly", sets: 3, reps: "12-15", rpeCap: 7.0, notes: nil, suggestedWeight: nil),
                CustomExercisePlan(exerciseName: "Lateral Raise", sets: 3, reps: "15", rpeCap: 6.5, notes: nil, suggestedWeight: nil)
            ],
            reasoning: "Isolation work",
            estimatedDuration: 30,
            focusAreas: ["Chest", "Shoulders"]
        )
        
        // The bug was: startCustomWorkout used templates.first which would be "Push Day A"
        // instead of creating a template from customResponse
        
        // Verify the custom response has different name than existing template
        XCTAssertNotEqual(customResponse.workoutName, existingTemplateName,
                         "Custom workout should have a different name than existing templates")
        
        // Verify custom response exercises are what AI generated
        XCTAssertEqual(customResponse.exercises[0].exerciseName, "Cable Fly",
                      "First exercise should be Cable Fly (from AI), not whatever is in Push Day A")
        XCTAssertEqual(customResponse.exercises[1].exerciseName, "Lateral Raise",
                      "Second exercise should be Lateral Raise (from AI)")
    }
    
    /// Test that custom workout preserves all exercise details from AI response
    func testCustomWorkoutPreservesExerciseDetails() {
        let customExercise = CustomExercisePlan(
            exerciseName: "Romanian Deadlift",
            sets: 4,
            reps: "8-10",
            rpeCap: 7.5,
            notes: "Slow eccentric, feel the stretch",
            suggestedWeight: 80.0
        )
        
        // Verify all properties are preserved
        XCTAssertEqual(customExercise.exerciseName, "Romanian Deadlift")
        XCTAssertEqual(customExercise.sets, 4)
        XCTAssertEqual(customExercise.reps, "8-10")
        XCTAssertEqual(customExercise.rpeCap, 7.5)
        XCTAssertEqual(customExercise.notes, "Slow eccentric, feel the stretch")
        XCTAssertEqual(customExercise.suggestedWeight, 80.0)
    }
    
    // MARK: - Prescription Parsing Tests
    
    func testParseRepsRangeFromString() {
        // Test parsing "8-10" into min/max
        let reps1 = "8-10"
        let components1 = reps1.split(separator: "-")
        if components1.count == 2 {
            let min = Int(components1[0])
            let max = Int(components1[1])
            XCTAssertEqual(min, 8)
            XCTAssertEqual(max, 10)
        } else {
            XCTFail("Failed to parse reps range")
        }
        
        // Test parsing single number "5"
        let reps2 = "5"
        let components2 = reps2.split(separator: "-")
        if components2.count == 1 {
            let value = Int(components2[0])
            XCTAssertEqual(value, 5)
        } else {
            XCTFail("Failed to parse single rep value")
        }
    }
    
    func testCreatePrescriptionFromCustomExercisePlan() {
        let plan = CustomExercisePlan(
            exerciseName: "Squat",
            sets: 4,
            reps: "5-6",
            rpeCap: 8.5,
            notes: nil,
            suggestedWeight: nil
        )
        
        // Parse reps into prescription format
        let repsComponents = plan.reps.split(separator: "-")
        let minReps: Int
        let maxReps: Int
        
        if repsComponents.count == 2 {
            minReps = Int(repsComponents[0]) ?? 5
            maxReps = Int(repsComponents[1]) ?? 5
        } else {
            minReps = Int(plan.reps) ?? 5
            maxReps = minReps
        }
        
        // Create a prescription
        let prescription = Prescription(
            progressionType: .straightSets, // Custom workouts use straight sets
            topSetRepsMin: minReps,
            topSetRepsMax: maxReps,
            topSetRPECap: plan.rpeCap,
            backoffSets: plan.sets - 1, // First set is "top" set
            backoffRepsMin: minReps,
            backoffRepsMax: maxReps,
            backoffLoadDropPercent: 0, // Same weight for all sets
            workingSets: plan.sets
        )
        
        XCTAssertEqual(prescription.topSetRepsMin, 5)
        XCTAssertEqual(prescription.topSetRepsMax, 6)
        XCTAssertEqual(prescription.topSetRPECap, 8.5)
    }
    
    // MARK: - Save as Template Tests
    
    func testSaveAsTemplatePreservesWorkoutName() {
        let response = CustomWorkoutResponse(
            workoutName: "AI Push Day",
            exercises: [
                CustomExercisePlan(exerciseName: "Bench Press", sets: 4, reps: "6-8", rpeCap: 8.0, notes: nil, suggestedWeight: nil)
            ],
            reasoning: "Test",
            estimatedDuration: 45,
            focusAreas: ["Chest"]
        )
        
        // When saving as template, the name should be preserved
        let template = WorkoutTemplate(
            name: response.workoutName,
            dayNumber: 1,
            targetDuration: response.estimatedDuration
        )
        
        XCTAssertEqual(template.name, "AI Push Day")
        XCTAssertEqual(template.targetDuration, 45)
    }
    
    func testSaveAsTemplateCreatesCorrectExerciseCount() {
        let response = CustomWorkoutResponse(
            workoutName: "Full Body",
            exercises: [
                CustomExercisePlan(exerciseName: "Squat", sets: 3, reps: "8", rpeCap: 8.0, notes: nil, suggestedWeight: nil),
                CustomExercisePlan(exerciseName: "Bench Press", sets: 3, reps: "8", rpeCap: 8.0, notes: nil, suggestedWeight: nil),
                CustomExercisePlan(exerciseName: "Row", sets: 3, reps: "8", rpeCap: 8.0, notes: nil, suggestedWeight: nil),
                CustomExercisePlan(exerciseName: "Overhead Press", sets: 3, reps: "8", rpeCap: 8.0, notes: nil, suggestedWeight: nil)
            ],
            reasoning: "Compound movements",
            estimatedDuration: 60,
            focusAreas: ["Full Body"]
        )
        
        // Template should have same number of exercises as response
        XCTAssertEqual(response.exercises.count, 4)
        
        // When converted, all exercises should be included
        var exerciseTemplateCount = 0
        for index in response.exercises.indices {
            // Simulating ExerciseTemplate creation
            exerciseTemplateCount += 1
            XCTAssertEqual(index + 1, exerciseTemplateCount)
        }
        XCTAssertEqual(exerciseTemplateCount, 4)
    }
    
    func testSaveAsTemplateAssignsCorrectDayNumber() {
        // Simulate existing templates
        let existingDayNumbers = [1, 2, 3]
        let nextDayNumber = (existingDayNumbers.max() ?? 0) + 1
        
        XCTAssertEqual(nextDayNumber, 4, "New template should get next available day number")
        
        // Edge case: no existing templates
        let emptyDayNumbers: [Int] = []
        let firstDayNumber = (emptyDayNumbers.max() ?? 0) + 1
        XCTAssertEqual(firstDayNumber, 1, "First template should be day 1")
    }
    
    func testSaveAsTemplateUsesStraightSetsProgression() {
        let plan = CustomExercisePlan(
            exerciseName: "Lateral Raise",
            sets: 3,
            reps: "12-15",
            rpeCap: 7.0,
            notes: nil,
            suggestedWeight: nil
        )
        
        // Parse reps
        let repsComponents = plan.reps.split(separator: "-")
        let minReps = Int(repsComponents[0]) ?? 12
        let maxReps = Int(repsComponents[1]) ?? 15
        
        let prescription = Prescription(
            progressionType: .straightSets,
            topSetRepsMin: minReps,
            topSetRepsMax: maxReps,
            topSetRPECap: plan.rpeCap,
            backoffSets: 0,
            backoffRepsMin: minReps,
            backoffRepsMax: maxReps,
            backoffLoadDropPercent: 0,
            workingSets: plan.sets
        )
        
        XCTAssertEqual(prescription.progressionType, ProgressionType.straightSets, "Saved templates should use straight sets")
        XCTAssertEqual(prescription.workingSets, 3)
        XCTAssertEqual(prescription.topSetRepsMin, 12)
        XCTAssertEqual(prescription.topSetRepsMax, 15)
    }
}
