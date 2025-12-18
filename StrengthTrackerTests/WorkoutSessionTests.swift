import XCTest
@testable import StrengthTracker

final class WorkoutSessionTests: XCTestCase {
    
    // MARK: - Default Values Tests
    
    func testWorkoutSession_DefaultLocation() {
        // Test that Location has expected default value
        let defaultLocation = Location.gym
        XCTAssertEqual(defaultLocation.rawValue, "Gym")
    }
    
    func testWorkoutSession_LocationCases() {
        let allCases = Location.allCases
        XCTAssertTrue(allCases.contains(.gym))
        XCTAssertTrue(allCases.contains(.home))
        XCTAssertTrue(allCases.contains(.mixed))
    }
    
    // MARK: - Relationship Tests
    
    func testWorkoutSession_TemplateRelationship() {
        let session = WorkoutSession()
        XCTAssertNil(session.template)
        
        let template = WorkoutTemplate(name: "Test Template", dayNumber: 1)
        session.template = template
        
        XCTAssertNotNil(session.template)
        XCTAssertEqual(session.template?.name, "Test Template")
        
        // Test optionality - should be able to set back to nil without crashing
        session.template = nil
        XCTAssertNil(session.template)
    }
    
    func testWorkoutSession_OrphanedSession() {
        // Simulates what happens if a template is deleted but session remains
        let session = WorkoutSession()
        let template = WorkoutTemplate(name: "Temporary Template", dayNumber: 1)
        session.template = template
        
        // In a real context (SwiftData), deleting template would nullify relationship 
        // depending on delete rule, but here we manually test nil handling
        session.template = nil
        
        XCTAssertNil(session.template)
        XCTAssertNoThrow(session.template?.name) // Safe access
    }
}

// MARK: - Readiness Tests

final class ReadinessStructTests: XCTestCase {
    
    func testReadiness_Default() {
        let readiness = Readiness.default
        
        XCTAssertEqual(readiness.energy, .ok)
        XCTAssertEqual(readiness.soreness, .none)
        XCTAssertEqual(readiness.timeAvailable, 60)
    }
    
    func testReadiness_ShouldReduceIntensity_LowEnergy() {
        let readiness = Readiness(energy: .low, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(readiness.shouldReduceIntensity)
    }
    
    func testReadiness_ShouldReduceIntensity_HighSoreness() {
        let readiness = Readiness(energy: .ok, soreness: .high, timeAvailable: 60)
        XCTAssertTrue(readiness.shouldReduceIntensity)
    }
    
    func testReadiness_ShouldNotReduceIntensity_Normal() {
        let readiness = Readiness(energy: .ok, soreness: .none, timeAvailable: 60)
        XCTAssertFalse(readiness.shouldReduceIntensity)
    }
    
    func testReadiness_ShouldIncreaseIntensity() {
        let readiness = Readiness(energy: .high, soreness: .none, timeAvailable: 60)
        XCTAssertTrue(readiness.shouldIncreaseIntensity)
    }
    
    func testReadiness_ShouldNotIncreaseIntensity_WithSoreness() {
        let readiness = Readiness(energy: .high, soreness: .mild, timeAvailable: 60)
        XCTAssertFalse(readiness.shouldIncreaseIntensity)
    }
    
    func testReadiness_Equality() {
        let r1 = Readiness(energy: .high, soreness: .none, timeAvailable: 60)
        let r2 = Readiness(energy: .high, soreness: .none, timeAvailable: 60)
        let r3 = Readiness(energy: .low, soreness: .none, timeAvailable: 60)
        
        XCTAssertEqual(r1, r2)
        XCTAssertNotEqual(r1, r3)
    }
    
    func testReadiness_Codable() {
        let readiness = Readiness(energy: .high, soreness: .mild, timeAvailable: 45)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(readiness)
            let decoded = try decoder.decode(Readiness.self, from: data)
            
            XCTAssertEqual(decoded.energy, readiness.energy)
            XCTAssertEqual(decoded.soreness, readiness.soreness)
            XCTAssertEqual(decoded.timeAvailable, readiness.timeAvailable)
        } catch {
            XCTFail("Failed to encode/decode Readiness: \(error)")
        }
    }
}

// MARK: - EnergyLevel Enum Tests

final class EnergyLevelTests: XCTestCase {
    
    func testEnergyLevel_AllCases() {
        let cases = EnergyLevel.allCases
        XCTAssertEqual(cases.count, 3)
        XCTAssertTrue(cases.contains(.low))
        XCTAssertTrue(cases.contains(.ok))
        XCTAssertTrue(cases.contains(.high))
    }
    
    func testEnergyLevel_RawValues() {
        XCTAssertEqual(EnergyLevel.low.rawValue, "Low")
        XCTAssertEqual(EnergyLevel.ok.rawValue, "OK")
        XCTAssertEqual(EnergyLevel.high.rawValue, "High")
    }
    
    func testEnergyLevel_Icons() {
        XCTAssertEqual(EnergyLevel.low.icon, "battery.25")
        XCTAssertEqual(EnergyLevel.ok.icon, "battery.50")
        XCTAssertEqual(EnergyLevel.high.icon, "battery.100")
    }
    
    func testEnergyLevel_Colors() {
        XCTAssertEqual(EnergyLevel.low.color, "red")
        XCTAssertEqual(EnergyLevel.ok.color, "yellow")
        XCTAssertEqual(EnergyLevel.high.color, "green")
    }
    
    func testEnergyLevel_Identifiable() {
        XCTAssertEqual(EnergyLevel.low.id, "Low")
        XCTAssertEqual(EnergyLevel.ok.id, "OK")
        XCTAssertEqual(EnergyLevel.high.id, "High")
    }
}

// MARK: - SorenessLevel Enum Tests

final class SorenessLevelTests: XCTestCase {
    
    func testSorenessLevel_AllCases() {
        let cases = SorenessLevel.allCases
        XCTAssertEqual(cases.count, 3)
        XCTAssertTrue(cases.contains(.none))
        XCTAssertTrue(cases.contains(.mild))
        XCTAssertTrue(cases.contains(.high))
    }
    
    func testSorenessLevel_RawValues() {
        XCTAssertEqual(SorenessLevel.none.rawValue, "None")
        XCTAssertEqual(SorenessLevel.mild.rawValue, "Mild")
        XCTAssertEqual(SorenessLevel.high.rawValue, "High")
    }
    
    func testSorenessLevel_Icons() {
        XCTAssertEqual(SorenessLevel.none.icon, "checkmark.circle.fill")
        XCTAssertEqual(SorenessLevel.mild.icon, "exclamationmark.circle.fill")
        XCTAssertEqual(SorenessLevel.high.icon, "xmark.circle.fill")
    }
    
    func testSorenessLevel_Colors() {
        XCTAssertEqual(SorenessLevel.none.color, "green")
        XCTAssertEqual(SorenessLevel.mild.color, "yellow")
        XCTAssertEqual(SorenessLevel.high.color, "red")
    }
}

// MARK: - SetType Enum Tests

final class SetTypeTests: XCTestCase {
    
    func testSetType_AllCases() {
        let cases = SetType.allCases
        XCTAssertTrue(cases.contains(.warmup))
        XCTAssertTrue(cases.contains(.working))
        XCTAssertTrue(cases.contains(.topSet))
        XCTAssertTrue(cases.contains(.backoff))
    }
    
    func testSetType_RawValues() {
        XCTAssertEqual(SetType.warmup.rawValue, "Warmup")
        XCTAssertEqual(SetType.working.rawValue, "Working")
        XCTAssertEqual(SetType.topSet.rawValue, "Top Set")
        XCTAssertEqual(SetType.backoff.rawValue, "Backoff")
    }
}

// MARK: - E1RM Calculator Integration Tests

final class WorkoutSetE1RMTests: XCTestCase {
    
    func testE1RM_CalculatedValue() {
        // Test e1RM calculation using the same formula
        let weight = 100.0
        let reps = 5
        let expectedE1RM = E1RMCalculator.calculate(weight: weight, reps: reps)
        
        // e1RM should be greater than actual weight
        XCTAssertGreaterThan(expectedE1RM, weight)
    }
    
    func testE1RM_SingleRep() {
        // For 1 rep, e1RM should equal the weight
        let e1RM = E1RMCalculator.calculate(weight: 200.0, reps: 1)
        XCTAssertEqual(e1RM, 200.0, accuracy: 0.1)
    }
    
    func testE1RM_HigherReps_HigherE1RM() {
        // Same weight with more reps should give higher e1RM
        let e1RM5 = E1RMCalculator.calculate(weight: 100.0, reps: 5)
        let e1RM8 = E1RMCalculator.calculate(weight: 100.0, reps: 8)
        
        XCTAssertGreaterThan(e1RM8, e1RM5)
    }
}

// MARK: - SetHistory Tests

final class SetHistoryTests: XCTestCase {
    
    func testSetHistory_FromWorkoutSet() {
        let exercise = Exercise(
            name: "Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipmentRequired: [.barbell]
        )
        
        let workoutSet = WorkoutSet(
            exercise: exercise,
            setType: .topSet,
            weight: 100.0,
            targetReps: 5,
            reps: 5,
            rpe: 8.0,
            orderIndex: 0
        )
        
        let historyDate = Date()
        let history = SetHistory(from: workoutSet, date: historyDate)
        
        XCTAssertEqual(history.weight, 100.0)
        XCTAssertEqual(history.reps, 5)
        XCTAssertEqual(history.rpe, 8.0)
        XCTAssertEqual(history.setType, .topSet)
        XCTAssertEqual(history.date, historyDate)
    }
    
    func testSetHistory_Codable() {
        let exercise = Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            equipmentRequired: [.barbell]
        )
        
        let workoutSet = WorkoutSet(
            exercise: exercise,
            setType: .topSet,
            weight: 80.0,
            targetReps: 6,
            reps: 6,
            rpe: 7.5,
            orderIndex: 0
        )
        
        let history = SetHistory(from: workoutSet, date: Date())
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(history)
            let decoded = try decoder.decode(SetHistory.self, from: data)
            
            XCTAssertEqual(decoded.weight, history.weight)
            XCTAssertEqual(decoded.reps, history.reps)
            XCTAssertEqual(decoded.rpe, history.rpe)
            XCTAssertEqual(decoded.setType, history.setType)
        } catch {
            XCTFail("Failed to encode/decode SetHistory: \(error)")
        }
    }
    
    func testSetHistory_E1RMCalculation() {
        let exercise = Exercise(
            name: "Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [],
            equipmentRequired: [.barbell]
        )
        
        let workoutSet = WorkoutSet(
            exercise: exercise,
            setType: .topSet,
            weight: 150.0,
            targetReps: 5,
            reps: 5,
            rpe: 8.0,
            orderIndex: 0
        )
        
        let history = SetHistory(from: workoutSet, date: Date())
        
        // e1RM should be calculated from the set's weight and reps
        let expectedE1RM = E1RMCalculator.calculate(weight: 150.0, reps: 5)
        XCTAssertEqual(history.e1RM, expectedE1RM)
    }
}

// MARK: - PainSeverity Enum Tests

final class PainSeverityTests: XCTestCase {
    
    func testPainSeverity_AllCases() {
        let cases = PainSeverity.allCases
        XCTAssertEqual(cases.count, 3)
        XCTAssertTrue(cases.contains(.mild))
        XCTAssertTrue(cases.contains(.moderate))
        XCTAssertTrue(cases.contains(.severe))
    }
    
    func testPainSeverity_RawValues() {
        XCTAssertEqual(PainSeverity.mild.rawValue, "Mild")
        XCTAssertEqual(PainSeverity.moderate.rawValue, "Moderate")
        XCTAssertEqual(PainSeverity.severe.rawValue, "Severe")
    }
    
    func testPainSeverity_Identifiable() {
        XCTAssertEqual(PainSeverity.mild.id, "Mild")
    }
}
