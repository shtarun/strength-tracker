import XCTest
@testable import StrengthTracker

final class DataTransferServiceTests: XCTestCase {
    
    // MARK: - Export Model Tests
    
    func testStrengthTrackerExportEncodesToJSON() throws {
        let export = StrengthTrackerExport(
            version: "1.0.0",
            exportedAt: Date(),
            profile: nil,
            equipment: nil,
            workoutSessions: [],
            painFlags: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(export)
        XCTAssertNotNil(data)
        XCTAssertTrue(data.count > 0)
        
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertTrue(jsonString?.contains("\"version\":\"1.0.0\"") ?? false)
    }
    
    func testStrengthTrackerExportDecodesFromJSON() throws {
        let json = """
        {
            "version": "1.0.0",
            "exportedAt": "2024-12-17T10:00:00Z",
            "profile": null,
            "equipment": null,
            "workoutSessions": [],
            "painFlags": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let data = json.data(using: .utf8)!
        let export = try decoder.decode(StrengthTrackerExport.self, from: data)
        
        XCTAssertEqual(export.version, "1.0.0")
        XCTAssertTrue(export.workoutSessions.isEmpty)
        XCTAssertTrue(export.painFlags.isEmpty)
    }
    
    func testExportedUserProfileEncoding() throws {
        let profile = ExportedUserProfile(
            id: UUID(),
            name: "Test User",
            goal: "strength",
            daysPerWeek: 4,
            preferredSplit: "upperLower",
            rpeFamiliarity: true,
            defaultRestTime: 180,
            unitSystem: "metric",
            appearanceMode: "auto",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(profile)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"name\":\"Test User\""))
        XCTAssertTrue(jsonString.contains("\"goal\":\"strength\""))
        XCTAssertTrue(jsonString.contains("\"daysPerWeek\":4"))
    }
    
    func testExportedEquipmentProfileEncoding() throws {
        let equipment = ExportedEquipmentProfile(
            id: UUID(),
            location: "gym",
            hasBarbell: true,
            hasRack: true,
            hasBench: true,
            hasAdjustableDumbbells: true,
            hasCables: true,
            hasMachines: false,
            hasPullUpBar: true,
            hasBands: false,
            hasMicroplates: true,
            availablePlates: [1.25, 2.5, 5.0, 10.0, 20.0, 25.0],
            dumbbellIncrements: [2.5, 5.0, 7.5, 10.0]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(equipment)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"location\":\"gym\""))
        XCTAssertTrue(jsonString.contains("\"hasBarbell\":true"))
        XCTAssertTrue(jsonString.contains("\"hasMachines\":false"))
    }
    
    func testExportedWorkoutSessionEncoding() throws {
        let session = ExportedWorkoutSession(
            id: UUID(),
            date: Date(),
            location: "gym",
            readiness: ExportedReadiness(
                energy: "high",
                soreness: "none",
                timeAvailable: 60
            ),
            plannedDuration: 60,
            actualDuration: 55,
            notes: "Great workout",
            isCompleted: true,
            insightText: "You hit a PR!",
            insightAction: "Increase weight next time",
            templateName: "Upper Body A",
            sets: [
                ExportedWorkoutSet(
                    id: UUID(),
                    exerciseName: "Bench Press",
                    exerciseMovementPattern: "horizontalPush",
                    setType: "topSet",
                    weight: 100.0,
                    targetReps: 5,
                    reps: 6,
                    rpe: 8.5,
                    targetRPE: 8.0,
                    isCompleted: true,
                    notes: nil,
                    timestamp: Date(),
                    orderIndex: 0
                )
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(session)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"location\":\"gym\""))
        XCTAssertTrue(jsonString.contains("\"isCompleted\":true"))
        XCTAssertTrue(jsonString.contains("\"exerciseName\":\"Bench Press\""))
    }
    
    func testExportedWorkoutSetEncoding() throws {
        let set = ExportedWorkoutSet(
            id: UUID(),
            exerciseName: "Squat",
            exerciseMovementPattern: "squat",
            setType: "working",
            weight: 140.0,
            targetReps: 8,
            reps: 8,
            rpe: 7.5,
            targetRPE: 7.5,
            isCompleted: true,
            notes: "Felt good",
            timestamp: Date(),
            orderIndex: 2
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(set)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"exerciseName\":\"Squat\""))
        XCTAssertTrue(jsonString.contains("\"weight\":140"))
        XCTAssertTrue(jsonString.contains("\"reps\":8"))
        XCTAssertTrue(jsonString.contains("\"setType\":\"working\""))
    }
    
    func testExportedPainFlagEncoding() throws {
        let painFlag = ExportedPainFlag(
            id: UUID(),
            exerciseName: "Deadlift",
            bodyPart: "lowerBack",
            severity: "moderate",
            notes: "Slight discomfort",
            flaggedDate: Date(),
            isResolved: false,
            resolvedDate: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(painFlag)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"exerciseName\":\"Deadlift\""))
        XCTAssertTrue(jsonString.contains("\"bodyPart\":\"lowerBack\""))
        XCTAssertTrue(jsonString.contains("\"severity\":\"moderate\""))
    }
    
    // MARK: - Import Insights Tests
    
    func testImportInsightsSummaryWithData() {
        let insights = ImportInsights(
            sessionsImported: 10,
            setsImported: 150,
            newExercisesFound: ["Custom Press", "Special Squat"],
            dateRange: Date().addingTimeInterval(-30*24*3600)...Date(),
            totalVolumeImported: 50000,
            topExercises: [
                (name: "Bench Press", sets: 45),
                (name: "Squat", sets: 40),
                (name: "Deadlift", sets: 30)
            ],
            duplicatesSkipped: 2,
            errors: []
        )
        
        let summary = insights.summary
        
        XCTAssertTrue(summary.contains("Import Complete"))
        XCTAssertTrue(summary.contains("10 workout sessions imported"))
        XCTAssertTrue(summary.contains("150 sets logged"))
        XCTAssertTrue(summary.contains("Bench Press"))
        XCTAssertTrue(summary.contains("Custom Press"))
        XCTAssertTrue(summary.contains("2 duplicate sessions skipped"))
    }
    
    func testImportInsightsSummaryWithNoData() {
        let insights = ImportInsights(
            sessionsImported: 0,
            setsImported: 0,
            newExercisesFound: [],
            dateRange: nil,
            totalVolumeImported: 0,
            topExercises: [],
            duplicatesSkipped: 0,
            errors: []
        )
        
        let summary = insights.summary
        
        XCTAssertTrue(summary.contains("Import Complete"))
        XCTAssertTrue(summary.contains("0 workout sessions imported"))
    }
    
    func testImportInsightsSummaryWithErrors() {
        let insights = ImportInsights(
            sessionsImported: 5,
            setsImported: 50,
            newExercisesFound: [],
            dateRange: Date()...Date(),
            totalVolumeImported: 10000,
            topExercises: [],
            duplicatesSkipped: 0,
            errors: ["Exercise not found: Unknown Exercise", "Invalid date format"]
        )
        
        let summary = insights.summary
        
        XCTAssertTrue(summary.contains("Warnings"))
        XCTAssertTrue(summary.contains("Exercise not found"))
    }
    
    func testImportInsightsVolumeFormatting() {
        // Test with small volume
        let smallVolumeInsights = ImportInsights(
            sessionsImported: 1,
            setsImported: 10,
            newExercisesFound: [],
            dateRange: Date()...Date(),
            totalVolumeImported: 500,
            topExercises: [],
            duplicatesSkipped: 0,
            errors: []
        )
        XCTAssertTrue(smallVolumeInsights.summary.contains("500 kg"))
        
        // Test with large volume (should show K)
        let largeVolumeInsights = ImportInsights(
            sessionsImported: 100,
            setsImported: 1000,
            newExercisesFound: [],
            dateRange: Date()...Date(),
            totalVolumeImported: 150000,
            topExercises: [],
            duplicatesSkipped: 0,
            errors: []
        )
        XCTAssertTrue(largeVolumeInsights.summary.contains("150K kg"))
    }
    
    // MARK: - Full Export/Import Round-Trip Tests
    
    func testFullExportRoundTrip() throws {
        let originalExport = StrengthTrackerExport(
            version: StrengthTrackerExport.currentVersion,
            exportedAt: Date(),
            profile: ExportedUserProfile(
                id: UUID(),
                name: "Test User",
                goal: "hypertrophy",
                daysPerWeek: 5,
                preferredSplit: "ppl",
                rpeFamiliarity: true,
                defaultRestTime: 120,
                unitSystem: "imperial",
                appearanceMode: "dark",
                createdAt: Date(),
                updatedAt: Date()
            ),
            equipment: ExportedEquipmentProfile(
                id: UUID(),
                location: "home",
                hasBarbell: true,
                hasRack: true,
                hasBench: true,
                hasAdjustableDumbbells: true,
                hasCables: false,
                hasMachines: false,
                hasPullUpBar: true,
                hasBands: true,
                hasMicroplates: false,
                availablePlates: [2.5, 5.0, 10.0, 25.0, 45.0],
                dumbbellIncrements: [5.0, 10.0, 15.0, 20.0]
            ),
            workoutSessions: [
                ExportedWorkoutSession(
                    id: UUID(),
                    date: Date(),
                    location: "home",
                    readiness: ExportedReadiness(
                        energy: "OK",
                        soreness: "Mild",
                        timeAvailable: 45
                    ),
                    plannedDuration: 45,
                    actualDuration: 50,
                    notes: "Quick session",
                    isCompleted: true,
                    insightText: nil,
                    insightAction: nil,
                    templateName: "Full Body",
                    sets: [
                        ExportedWorkoutSet(
                            id: UUID(),
                            exerciseName: "Pull-up",
                            exerciseMovementPattern: "verticalPull",
                            setType: "working",
                            weight: 0,
                            targetReps: 10,
                            reps: 12,
                            rpe: 7.0,
                            targetRPE: 7.0,
                            isCompleted: true,
                            notes: nil,
                            timestamp: Date(),
                            orderIndex: 0
                        )
                    ]
                )
            ],
            painFlags: []
        )
        
        // Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(originalExport)
        
        // Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedExport = try decoder.decode(StrengthTrackerExport.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedExport.version, originalExport.version)
        XCTAssertEqual(decodedExport.profile?.name, "Test User")
        XCTAssertEqual(decodedExport.profile?.goal, "hypertrophy")
        XCTAssertEqual(decodedExport.equipment?.location, "home")
        XCTAssertEqual(decodedExport.workoutSessions.count, 1)
        XCTAssertEqual(decodedExport.workoutSessions.first?.sets.count, 1)
        XCTAssertEqual(decodedExport.workoutSessions.first?.sets.first?.exerciseName, "Pull-up")
    }
    
    func testExportVersionIsCorrect() {
        XCTAssertEqual(StrengthTrackerExport.currentVersion, "1.0.0")
    }
    
    func testExportedReadinessEncoding() throws {
        let readiness = ExportedReadiness(
            energy: "High",
            soreness: "None",
            timeAvailable: 90
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(readiness)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"energy\":\"High\""))
        XCTAssertTrue(jsonString.contains("\"soreness\":\"None\""))
        XCTAssertTrue(jsonString.contains("\"timeAvailable\":90"))
    }
    
    // MARK: - Edge Cases
    
    func testEmptyWorkoutSessionExport() throws {
        let session = ExportedWorkoutSession(
            id: UUID(),
            date: Date(),
            location: "gym",
            readiness: nil,
            plannedDuration: 60,
            actualDuration: nil,
            notes: nil,
            isCompleted: false,
            insightText: nil,
            insightAction: nil,
            templateName: nil,
            sets: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(session)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decoded = try decoder.decode(ExportedWorkoutSession.self, from: data)
        
        XCTAssertNil(decoded.readiness)
        XCTAssertNil(decoded.actualDuration)
        XCTAssertNil(decoded.notes)
        XCTAssertFalse(decoded.isCompleted)
        XCTAssertTrue(decoded.sets.isEmpty)
    }
    
    func testWorkoutSetWithNilOptionalFields() throws {
        let set = ExportedWorkoutSet(
            id: UUID(),
            exerciseName: "Exercise",
            exerciseMovementPattern: "isolation",
            setType: "warmup",
            weight: 20.0,
            targetReps: 10,
            reps: 10,
            rpe: nil,
            targetRPE: nil,
            isCompleted: true,
            notes: nil,
            timestamp: Date(),
            orderIndex: 0
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(set)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decoded = try decoder.decode(ExportedWorkoutSet.self, from: data)
        
        XCTAssertNil(decoded.rpe)
        XCTAssertNil(decoded.targetRPE)
        XCTAssertNil(decoded.notes)
    }
    
    func testPainFlagResolvedState() throws {
        let resolvedFlag = ExportedPainFlag(
            id: UUID(),
            exerciseName: "Squat",
            bodyPart: "knee",
            severity: "Mild",
            notes: "Was sore for a week",
            flaggedDate: Date().addingTimeInterval(-7*24*3600),
            isResolved: true,
            resolvedDate: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(resolvedFlag)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decoded = try decoder.decode(ExportedPainFlag.self, from: data)
        
        XCTAssertTrue(decoded.isResolved)
        XCTAssertNotNil(decoded.resolvedDate)
    }
    
    // MARK: - JSON Structure Validation
    
    func testExportJSONStructureContainsAllTopLevelKeys() throws {
        // Create export with actual data (not nil) to ensure all keys are present
        let export = StrengthTrackerExport(
            version: "1.0.0",
            exportedAt: Date(),
            profile: ExportedUserProfile(
                id: UUID(),
                name: "Test",
                goal: "strength",
                daysPerWeek: 4,
                preferredSplit: "upperLower",
                rpeFamiliarity: true,
                defaultRestTime: 120,
                unitSystem: "metric",
                appearanceMode: "auto",
                createdAt: Date(),
                updatedAt: Date()
            ),
            equipment: ExportedEquipmentProfile(
                id: UUID(),
                location: "gym",
                hasBarbell: true,
                hasRack: true,
                hasBench: true,
                hasAdjustableDumbbells: false,
                hasCables: false,
                hasMachines: false,
                hasPullUpBar: false,
                hasBands: false,
                hasMicroplates: false,
                availablePlates: [],
                dumbbellIncrements: []
            ),
            workoutSessions: [],
            painFlags: []
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(export)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["version"])
        XCTAssertNotNil(json?["exportedAt"])
        XCTAssertTrue(json?.keys.contains("profile") ?? false)
        XCTAssertTrue(json?.keys.contains("equipment") ?? false)
        XCTAssertTrue(json?.keys.contains("workoutSessions") ?? false)
        XCTAssertTrue(json?.keys.contains("painFlags") ?? false)
    }
    
    // MARK: - Export File Name Tests
    
    @MainActor
    func testExportFileNameFormat() {
        let fileName = DataTransferService.shared.exportFileName()
        
        XCTAssertTrue(fileName.hasPrefix("StrengthTracker_"))
        XCTAssertTrue(fileName.hasSuffix(".json"))
        XCTAssertTrue(fileName.count > 20) // StrengthTracker_YYYY-MM-DD_HHMMSS.json
    }
}
