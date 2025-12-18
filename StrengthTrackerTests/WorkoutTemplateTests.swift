import XCTest
@testable import StrengthTracker

final class WorkoutTemplateTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testWorkoutTemplate_Initialization() {
        let template = WorkoutTemplate(
            name: "Full Body A",
            dayNumber: 1,
            targetDuration: 60,
            notes: "Focus on form"
        )
        
        XCTAssertEqual(template.name, "Full Body A")
        XCTAssertEqual(template.dayNumber, 1)
        XCTAssertEqual(template.targetDuration, 60)
        XCTAssertEqual(template.notes, "Focus on form")
        XCTAssertTrue(template.exercises.isEmpty)
    }
    
    // MARK: - Relationship Tests
    
    func testWorkoutTemplate_ExerciseRelationship() {
        let template = WorkoutTemplate(name: "Test Template", dayNumber: 1)
        
        let exercise = Exercise(name: "Squat")
        let exerciseTemplate = ExerciseTemplate(
            exercise: exercise,
            orderIndex: 0,
            prescription: Prescription.default
        )
        
        template.exercises.append(exerciseTemplate)
        
        XCTAssertEqual(template.exercises.count, 1)
        XCTAssertEqual(template.exercises.first?.exercise?.name, "Squat")
    }
    
    // MARK: - Sorting Tests
    
    func testWorkoutTemplate_SortedExercises() {
        let template = WorkoutTemplate(name: "Sorted Template", dayNumber: 1)
        
        let ex1 = ExerciseTemplate(orderIndex: 2)
        let ex2 = ExerciseTemplate(orderIndex: 0)
        let ex3 = ExerciseTemplate(orderIndex: 1)
        
        template.exercises = [ex1, ex2, ex3]
        
        let sorted = template.sortedExercises
        
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].orderIndex, 0)
        XCTAssertEqual(sorted[1].orderIndex, 1)
        XCTAssertEqual(sorted[2].orderIndex, 2)
    }
}
