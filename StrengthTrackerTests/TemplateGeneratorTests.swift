import XCTest
@testable import StrengthTracker

final class TemplateGeneratorTests: XCTestCase {
    
    // MARK: - Helper Methods
    
    private func makeProfile(
        goal: Goal = .both,
        daysPerWeek: Int = 4,
        split: Split = .upperLower
    ) -> UserProfile {
        return UserProfile(
            name: "Test User",
            goal: goal,
            daysPerWeek: daysPerWeek,
            preferredSplit: split
        )
    }
    
    private func makeEquipmentProfile(
        location: Location = .gym,
        hasBarbell: Bool = true,
        hasCables: Bool = true,
        hasMachines: Bool = true
    ) -> EquipmentProfile {
        return EquipmentProfile(
            location: location,
            hasBarbell: hasBarbell,
            hasCables: hasCables,
            hasMachines: hasMachines
        )
    }
    
    // MARK: - Split Tests
    
    func testSplit_UpperLower_ReturnsFourDays() {
        let profile = makeProfile(daysPerWeek: 4, split: .upperLower)
        
        XCTAssertEqual(profile.daysPerWeek, 4)
        XCTAssertEqual(profile.preferredSplit, .upperLower)
        XCTAssertEqual(Split.upperLower.daysPerWeek, 4)
    }
    
    func testSplit_PPL_ReturnsSixDays() {
        let profile = makeProfile(daysPerWeek: 6, split: .ppl)
        
        XCTAssertEqual(profile.preferredSplit, .ppl)
        XCTAssertEqual(profile.daysPerWeek, 6)
        XCTAssertEqual(Split.ppl.daysPerWeek, 6)
    }
    
    func testSplit_FullBody_ReturnsThreeDays() {
        let profile = makeProfile(daysPerWeek: 3, split: .fullBody)
        
        XCTAssertEqual(profile.preferredSplit, .fullBody)
        XCTAssertEqual(profile.daysPerWeek, 3)
        XCTAssertEqual(Split.fullBody.daysPerWeek, 3)
    }
    
    func testSplit_Custom_ReturnsZeroDays() {
        XCTAssertEqual(Split.custom.daysPerWeek, 0)
    }
    
    // MARK: - Equipment Filtering Tests
    
    func testEquipmentFiltering_HomeGym_NoCables() {
        let equipment = makeEquipmentProfile(location: .home, hasCables: false, hasMachines: false)
        
        XCTAssertFalse(equipment.hasCables)
        XCTAssertFalse(equipment.hasMachines)
    }
    
    func testEquipmentFiltering_GymHasAllEquipment() {
        let equipment = makeEquipmentProfile(location: .gym)
        
        XCTAssertTrue(equipment.hasBarbell)
        XCTAssertTrue(equipment.hasCables)
        XCTAssertTrue(equipment.hasMachines)
    }
    
    func testEquipmentProfile_AvailablePlates() {
        let equipment = EquipmentProfile()
        
        XCTAssertEqual(equipment.availablePlates, EquipmentProfile.defaultPlates)
    }
    
    // MARK: - Goal-Based Tests
    
    func testGoal_Strength() {
        let profile = makeProfile(goal: .strength)
        XCTAssertEqual(profile.goal, .strength)
    }
    
    func testGoal_Hypertrophy() {
        let profile = makeProfile(goal: .hypertrophy)
        XCTAssertEqual(profile.goal, .hypertrophy)
    }
    
    func testGoal_Both() {
        let profile = makeProfile(goal: .both)
        XCTAssertEqual(profile.goal, .both)
    }
    
    // MARK: - Days Per Week Tests
    
    func testDaysPerWeek_ValidRanges() {
        for days in 2...7 {
            let profile = makeProfile(daysPerWeek: days)
            XCTAssertEqual(profile.daysPerWeek, days)
        }
    }
}

// MARK: - WorkoutTemplate Tests

final class WorkoutTemplateTests: XCTestCase {
    
    func testWorkoutTemplate_Creation() {
        let template = WorkoutTemplate(
            name: "Upper A",
            dayNumber: 1,
            targetDuration: 75
        )
        
        XCTAssertEqual(template.name, "Upper A")
        XCTAssertEqual(template.dayNumber, 1)
        XCTAssertEqual(template.targetDuration, 75)
    }
    
    func testWorkoutTemplate_DefaultDuration() {
        let template = WorkoutTemplate(
            name: "Lower A",
            dayNumber: 2
        )
        
        XCTAssertEqual(template.targetDuration, 60)
    }
    
    func testWorkoutTemplate_ExercisesStartEmpty() {
        let template = WorkoutTemplate(
            name: "Push Day",
            dayNumber: 1
        )
        
        XCTAssertTrue(template.exercises.isEmpty)
    }
}

// MARK: - ExerciseTemplate Tests

final class ExerciseTemplateTests: XCTestCase {
    
    func testExerciseTemplate_Creation() {
        let exercise = Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            equipmentRequired: [.barbell]
        )
        
        let prescription = Prescription(
            progressionType: .topSetBackoff,
            topSetRepsMin: 4,
            topSetRepsMax: 6,
            topSetRPECap: 8.0,
            backoffSets: 3,
            backoffRepsMin: 6,
            backoffRepsMax: 10,
            backoffLoadDropPercent: 0.10,
            workingSets: 1
        )
        
        let template = ExerciseTemplate(
            exercise: exercise,
            orderIndex: 1,
            isOptional: false,
            prescription: prescription
        )
        
        XCTAssertEqual(template.orderIndex, 1)
        XCTAssertEqual(template.isOptional, false)
        XCTAssertEqual(template.prescription.topSetRPECap, 8.0)
        XCTAssertEqual(template.prescription.topSetRepsMin, 4)
        XCTAssertEqual(template.prescription.topSetRepsMax, 6)
        XCTAssertEqual(template.prescription.backoffSets, 3)
    }
    
    func testExerciseTemplate_WithDefaultPrescription() {
        let exercise = Exercise(
            name: "Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipmentRequired: [.barbell]
        )
        
        let template = ExerciseTemplate(
            exercise: exercise,
            orderIndex: 0
        )
        
        // Default prescription values
        XCTAssertEqual(template.prescription.topSetRepsMin, 4)
        XCTAssertEqual(template.prescription.topSetRepsMax, 6)
        XCTAssertEqual(template.prescription.topSetRPECap, 8.0)
        XCTAssertEqual(template.prescription.backoffSets, 3)
    }
    
    func testExerciseTemplate_HypertrophyPrescription() {
        let exercise = Exercise(
            name: "Lat Pulldown",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.cable]
        )
        
        let template = ExerciseTemplate(
            exercise: exercise,
            orderIndex: 2,
            prescription: .hypertrophy
        )
        
        XCTAssertEqual(template.prescription.topSetRepsMin, 8)
        XCTAssertEqual(template.prescription.topSetRepsMax, 12)
        XCTAssertEqual(template.prescription.progressionType, .doubleProgression)
    }
    
    func testExerciseTemplate_StrengthPrescription() {
        let exercise = Exercise(
            name: "Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [.barbell]
        )
        
        let template = ExerciseTemplate(
            exercise: exercise,
            orderIndex: 0,
            prescription: .strength
        )
        
        XCTAssertEqual(template.prescription.topSetRepsMin, 3)
        XCTAssertEqual(template.prescription.topSetRepsMax, 5)
        XCTAssertEqual(template.prescription.progressionType, .topSetBackoff)
    }
    
    func testExerciseTemplate_Optional() {
        let exercise = Exercise(
            name: "Bicep Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipmentRequired: [.dumbbell]
        )
        
        let template = ExerciseTemplate(
            exercise: exercise,
            orderIndex: 5,
            isOptional: true
        )
        
        XCTAssertTrue(template.isOptional)
    }
}

// MARK: - Prescription Tests

final class PrescriptionTests: XCTestCase {
    
    func testPrescription_DefaultValues() {
        let prescription = Prescription.default
        
        XCTAssertEqual(prescription.progressionType, .topSetBackoff)
        XCTAssertEqual(prescription.topSetRepsMin, 4)
        XCTAssertEqual(prescription.topSetRepsMax, 6)
        XCTAssertEqual(prescription.topSetRPECap, 8.0)
        XCTAssertEqual(prescription.backoffSets, 3)
        XCTAssertEqual(prescription.backoffRepsMin, 6)
        XCTAssertEqual(prescription.backoffRepsMax, 10)
        XCTAssertEqual(prescription.backoffLoadDropPercent, 0.10)
        XCTAssertEqual(prescription.workingSets, 3)
    }
    
    func testPrescription_HypertrophyValues() {
        let prescription = Prescription.hypertrophy
        
        XCTAssertEqual(prescription.progressionType, .doubleProgression)
        XCTAssertEqual(prescription.topSetRepsMin, 8)
        XCTAssertEqual(prescription.topSetRepsMax, 12)
        XCTAssertEqual(prescription.topSetRPECap, 8.5)
        XCTAssertEqual(prescription.backoffSets, 0)
        XCTAssertEqual(prescription.workingSets, 3)
    }
    
    func testPrescription_StrengthValues() {
        let prescription = Prescription.strength
        
        XCTAssertEqual(prescription.progressionType, .topSetBackoff)
        XCTAssertEqual(prescription.topSetRepsMin, 3)
        XCTAssertEqual(prescription.topSetRepsMax, 5)
        XCTAssertEqual(prescription.topSetRPECap, 8.0)
        XCTAssertEqual(prescription.backoffSets, 3)
        XCTAssertEqual(prescription.backoffLoadDropPercent, 0.12)
    }
    
    func testPrescription_Equatable() {
        let prescription1 = Prescription.default
        let prescription2 = Prescription.default
        let prescription3 = Prescription.hypertrophy
        
        XCTAssertEqual(prescription1, prescription2)
        XCTAssertNotEqual(prescription1, prescription3)
    }
    
    func testPrescription_CustomValues() {
        let prescription = Prescription(
            progressionType: .doubleProgression,
            topSetRepsMin: 5,
            topSetRepsMax: 8,
            topSetRPECap: 7.5,
            backoffSets: 2,
            backoffRepsMin: 8,
            backoffRepsMax: 12,
            backoffLoadDropPercent: 0.15,
            workingSets: 4
        )
        
        XCTAssertEqual(prescription.topSetRepsMin, 5)
        XCTAssertEqual(prescription.topSetRepsMax, 8)
        XCTAssertEqual(prescription.topSetRPECap, 7.5)
        XCTAssertEqual(prescription.backoffSets, 2)
        XCTAssertEqual(prescription.workingSets, 4)
    }
}

// MARK: - Split Enum Tests

final class SplitEnumTests: XCTestCase {
    
    func testSplit_AllCases() {
        XCTAssertEqual(Split.allCases.count, 4)
        XCTAssertTrue(Split.allCases.contains(.upperLower))
        XCTAssertTrue(Split.allCases.contains(.ppl))
        XCTAssertTrue(Split.allCases.contains(.fullBody))
        XCTAssertTrue(Split.allCases.contains(.custom))
    }
    
    func testSplit_RawValues() {
        XCTAssertEqual(Split.upperLower.rawValue, "Upper/Lower")
        XCTAssertEqual(Split.ppl.rawValue, "Push/Pull/Legs")
        XCTAssertEqual(Split.fullBody.rawValue, "Full Body")
        XCTAssertEqual(Split.custom.rawValue, "Custom")
    }
    
    func testSplit_DayNames() {
        XCTAssertEqual(Split.upperLower.dayNames.count, 4)
        XCTAssertEqual(Split.ppl.dayNames.count, 6)
        XCTAssertEqual(Split.fullBody.dayNames.count, 3)
        XCTAssertEqual(Split.custom.dayNames.count, 0)
    }
    
    func testSplit_UpperLower_DayNames() {
        let dayNames = Split.upperLower.dayNames
        XCTAssertEqual(dayNames[0], "Upper A")
        XCTAssertEqual(dayNames[1], "Lower A")
        XCTAssertEqual(dayNames[2], "Upper B")
        XCTAssertEqual(dayNames[3], "Lower B")
    }
    
    func testSplit_PPL_DayNames() {
        let dayNames = Split.ppl.dayNames
        XCTAssertEqual(dayNames[0], "Push")
        XCTAssertEqual(dayNames[1], "Pull")
        XCTAssertEqual(dayNames[2], "Legs")
    }
}
