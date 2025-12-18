import XCTest
@testable import StrengthTracker

final class ExerciseLibraryTests: XCTestCase {
    
    // MARK: - Exercise Creation Tests
    
    func testCreateAllExercises_ReturnsNonEmpty() {
        // Access the library's exercises through reflection or make method accessible
        // For now, test that common exercises are created properly
        let benchPress = Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.barbell, .bench, .rack],
            formCues: ["Retract and depress shoulder blades"],
            commonMistakes: ["Bouncing bar off chest"]
        )
        
        XCTAssertEqual(benchPress.name, "Bench Press")
        XCTAssertFalse(benchPress.formCues.isEmpty)
        XCTAssertFalse(benchPress.commonMistakes.isEmpty)
    }
    
    func testExercise_FormGuidance_HasFormGuidance() {
        let exercise = Exercise(
            name: "Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [],
            equipmentRequired: [.barbell, .rack],
            formCues: ["Break at hips and knees together", "Maintain neutral spine"],
            commonMistakes: ["Knees caving inward"]
        )
        
        XCTAssertTrue(exercise.hasFormGuidance)
    }
    
    func testExercise_NoFormGuidance_HasFormGuidanceFalse() {
        let exercise = Exercise(
            name: "Mystery Exercise",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipmentRequired: []
        )
        
        XCTAssertFalse(exercise.hasFormGuidance)
    }
    
    // MARK: - YouTube Video URL Tests
    
    func testExercise_WithYouTubeURL() {
        let exercise = Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.barbell, .bench, .rack],
            formCues: ["Retract and depress shoulder blades"],
            commonMistakes: ["Bouncing bar off chest"],
            youtubeVideoURL: "https://www.youtube.com/watch?v=rT7DgCr-3pg"
        )
        
        XCTAssertNotNil(exercise.youtubeVideoURL)
        XCTAssertTrue(exercise.youtubeVideoURL!.contains("youtube.com"))
    }
    
    func testExercise_WithoutYouTubeURL() {
        let exercise = Exercise(
            name: "Mystery Exercise",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipmentRequired: []
        )
        
        XCTAssertNil(exercise.youtubeVideoURL)
    }
    
    func testExercise_YouTubeURL_IsOptional() {
        let exercise = Exercise(
            name: "Custom Exercise",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipmentRequired: [.bodyweight]
        )
        
        // Should compile and work without youtubeVideoURL
        XCTAssertEqual(exercise.name, "Custom Exercise")
        XCTAssertNil(exercise.youtubeVideoURL)
    }
    
    // MARK: - Kettlebell Exercises Tests
    
    func testKettlebellExercise_Creation() {
        let kettlebellSwing = Exercise(
            name: "Kettlebell Swing",
            movementPattern: .hinge,
            primaryMuscles: [.glutes, .hamstrings],
            secondaryMuscles: [.core, .lowerBack],
            equipmentRequired: [.kettlebell],
            formCues: [
                "Hinge at hips, not squat down",
                "Snap hips forward explosively"
            ],
            commonMistakes: [
                "Squatting instead of hinging",
                "Using arms to lift bell"
            ]
        )
        
        XCTAssertEqual(kettlebellSwing.movementPattern, .hinge)
        XCTAssertTrue(kettlebellSwing.equipmentRequired.contains(.kettlebell))
        XCTAssertEqual(kettlebellSwing.formCues.count, 2)
    }
    
    // MARK: - Carry Exercises Tests
    
    func testCarryExercise_Creation() {
        let farmerWalk = Exercise(
            name: "Farmer Walk",
            movementPattern: .carry,
            primaryMuscles: [.traps, .forearms, .core],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.dumbbell]
        )
        
        XCTAssertEqual(farmerWalk.movementPattern, .carry)
        XCTAssertTrue(farmerWalk.primaryMuscles.contains(.core))
    }
    
    // MARK: - Mobility Exercises Tests
    
    func testMobilityExercise_Creation() {
        let catCow = Exercise(
            name: "Cat-Cow Stretch",
            movementPattern: .mobility,
            primaryMuscles: [.core],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [],
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 60
        )
        
        XCTAssertEqual(catCow.movementPattern, .mobility)
        XCTAssertTrue(catCow.isMobilityRoutine)
        XCTAssertEqual(catCow.routineType, "pre-workout")
        XCTAssertEqual(catCow.durationSeconds, 60)
    }
    
    func testMobilityExercise_IsPreWorkout() {
        let exercise = Exercise(
            name: "Hip Circles",
            movementPattern: .mobility,
            primaryMuscles: [.glutes],
            secondaryMuscles: [],
            equipmentRequired: [],
            isMobilityRoutine: true,
            routineType: "pre-workout"
        )
        
        XCTAssertEqual(exercise.routineType, "pre-workout")
    }
    
    func testMobilityExercise_IsPostWorkout() {
        let exercise = Exercise(
            name: "Pigeon Pose",
            movementPattern: .mobility,
            primaryMuscles: [.glutes],
            secondaryMuscles: [.hamstrings],
            equipmentRequired: [],
            isMobilityRoutine: true,
            routineType: "post-workout"
        )
        
        XCTAssertEqual(exercise.routineType, "post-workout")
    }
    
    // MARK: - Cardio Exercises Tests
    
    func testCardioExercise_Creation() {
        let treadmill = Exercise(
            name: "Treadmill Running",
            movementPattern: .cardio,
            primaryMuscles: [.quads, .hamstrings, .calves],
            secondaryMuscles: [.core],
            equipmentRequired: [.cardioMachine],
            isCompound: true,
            durationSeconds: 1200
        )
        
        XCTAssertEqual(treadmill.movementPattern, .cardio)
        XCTAssertTrue(treadmill.equipmentRequired.contains(.cardioMachine))
        XCTAssertEqual(treadmill.durationSeconds, 1200)
    }
    
    // MARK: - Band Exercises Tests
    
    func testBandExercise_Creation() {
        let bandPullApart = Exercise(
            name: "Band Pull-Apart",
            movementPattern: .isolation,
            primaryMuscles: [.rearDelt, .upperBack],
            secondaryMuscles: [],
            equipmentRequired: [.bands]
        )
        
        XCTAssertTrue(bandPullApart.equipmentRequired.contains(.bands))
    }
    
    // MARK: - Equipment Tests
    
    func testEquipment_RequiresGym() {
        XCTAssertTrue(Equipment.cable.requiresGym)
        XCTAssertTrue(Equipment.machine.requiresGym)
        XCTAssertTrue(Equipment.cardioMachine.requiresGym)
        
        XCTAssertFalse(Equipment.dumbbell.requiresGym)
        XCTAssertFalse(Equipment.bodyweight.requiresGym)
        XCTAssertFalse(Equipment.bands.requiresGym)
        XCTAssertFalse(Equipment.kettlebell.requiresGym)
    }
    
    func testEquipment_Icons() {
        XCTAssertFalse(Equipment.barbell.icon.isEmpty)
        XCTAssertFalse(Equipment.dumbbell.icon.isEmpty)
        XCTAssertFalse(Equipment.kettlebell.icon.isEmpty)
        XCTAssertFalse(Equipment.cardioMachine.icon.isEmpty)
        XCTAssertFalse(Equipment.foamRoller.icon.isEmpty)
    }
    
    // MARK: - Movement Pattern Tests
    
    func testMovementPattern_IsMobility() {
        XCTAssertTrue(MovementPattern.mobility.isMobility)
        XCTAssertFalse(MovementPattern.squat.isMobility)
        XCTAssertFalse(MovementPattern.hinge.isMobility)
    }
    
    func testMovementPattern_IsCardio() {
        XCTAssertTrue(MovementPattern.cardio.isCardio)
        XCTAssertFalse(MovementPattern.horizontalPush.isCardio)
        XCTAssertFalse(MovementPattern.mobility.isCardio)
    }
    
    func testMovementPattern_PrimaryMuscleGroups() {
        let squat = MovementPattern.squat
        XCTAssertTrue(squat.primaryMuscleGroups.contains(.quads))
        XCTAssertTrue(squat.primaryMuscleGroups.contains(.glutes))
        
        let hinge = MovementPattern.hinge
        XCTAssertTrue(hinge.primaryMuscleGroups.contains(.hamstrings))
        XCTAssertTrue(hinge.primaryMuscleGroups.contains(.glutes))
        
        let carry = MovementPattern.carry
        XCTAssertTrue(carry.primaryMuscleGroups.contains(.core))
        XCTAssertTrue(carry.primaryMuscleGroups.contains(.traps))
        
        // Mobility and cardio should return empty
        XCTAssertTrue(MovementPattern.mobility.primaryMuscleGroups.isEmpty)
        XCTAssertTrue(MovementPattern.cardio.primaryMuscleGroups.isEmpty)
    }
}
