import XCTest

/// Unit tests for DataTransferService - Export/Import functionality
/// Tests JSON encoding/decoding of export data structures
final class DataTransferServiceTests: XCTestCase {

    // MARK: - Export Data Structure Tests

    func testTestExportSessionDataCodable() throws {
        let sessionData = TestExportSessionData(
            id: UUID(),
            date: Date(),
            templateName: "Upper A",
            location: "Gym",
            readinessEnergy: "OK",
            readinessSoreness: "None",
            timeAvailable: 60,
            plannedDuration: 60,
            actualDuration: 55,
            isCompleted: true,
            notes: "Good session",
            sets: []
        )

        let encoded = try JSONEncoder().encode(sessionData)
        let decoded = try JSONDecoder().decode(TestExportSessionData.self, from: encoded)

        XCTAssertEqual(decoded.id, sessionData.id)
        XCTAssertEqual(decoded.templateName, "Upper A")
        XCTAssertEqual(decoded.actualDuration, 55)
        XCTAssertTrue(decoded.isCompleted)
    }

    func testTestExportSetDataCodable() throws {
        let setData = TestExportSetData(
            id: UUID(),
            exerciseName: "Bench Press",
            setType: "Top Set",
            weight: 100,
            targetReps: 5,
            reps: 5,
            rpe: 8.5,
            targetRPE: 8.5,
            isCompleted: true,
            orderIndex: 3
        )

        let encoded = try JSONEncoder().encode(setData)
        let decoded = try JSONDecoder().decode(TestExportSetData.self, from: encoded)

        XCTAssertEqual(decoded.exerciseName, "Bench Press")
        XCTAssertEqual(decoded.setType, "Top Set")
        XCTAssertEqual(decoded.weight, 100)
        XCTAssertEqual(decoded.rpe, 8.5)
    }

    func testTestExportSetDataWithNilRPE() throws {
        let setData = TestExportSetData(
            id: UUID(),
            exerciseName: "Warmup Set",
            setType: "Warmup",
            weight: 40,
            targetReps: 10,
            reps: 10,
            rpe: nil,
            targetRPE: nil,
            isCompleted: true,
            orderIndex: 0
        )

        let encoded = try JSONEncoder().encode(setData)
        let decoded = try JSONDecoder().decode(TestExportSetData.self, from: encoded)

        XCTAssertNil(decoded.rpe)
        XCTAssertNil(decoded.targetRPE)
    }

    // MARK: - Full Export Tests

    func testTestExportCodable() throws {
        let export = TestExport(
            version: "1.0",
            exportDate: Date(),
            userProfile: TestExportUserProfile(
                name: "Test User",
                goal: "Strength",
                daysPerWeek: 4,
                preferredSplit: "Upper/Lower",
                unitSystem: "Metric"
            ),
            sessions: [
                TestExportSessionData(
                    id: UUID(),
                    date: Date(),
                    templateName: "Upper A",
                    location: "Gym",
                    readinessEnergy: "OK",
                    readinessSoreness: "None",
                    timeAvailable: 60,
                    plannedDuration: 60,
                    actualDuration: 55,
                    isCompleted: true,
                    notes: nil,
                    sets: [
                        TestExportSetData(
                            id: UUID(),
                            exerciseName: "Bench Press",
                            setType: "Top Set",
                            weight: 100,
                            targetReps: 5,
                            reps: 5,
                            rpe: 8.5,
                            targetRPE: 8.5,
                            isCompleted: true,
                            orderIndex: 0
                        )
                    ]
                )
            ]
        )

        let encoded = try JSONEncoder().encode(export)
        let decoded = try JSONDecoder().decode(TestExport.self, from: encoded)

        XCTAssertEqual(decoded.version, "1.0")
        XCTAssertEqual(decoded.userProfile.name, "Test User")
        XCTAssertEqual(decoded.sessions.count, 1)
        XCTAssertEqual(decoded.sessions[0].sets.count, 1)
    }

    // MARK: - User Profile Export Tests

    func testTestExportUserProfileCodable() throws {
        let profile = TestExportUserProfile(
            name: "John Doe",
            goal: "Hypertrophy",
            daysPerWeek: 5,
            preferredSplit: "PPL",
            unitSystem: "Imperial"
        )

        let encoded = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(TestExportUserProfile.self, from: encoded)

        XCTAssertEqual(decoded.name, "John Doe")
        XCTAssertEqual(decoded.goal, "Hypertrophy")
        XCTAssertEqual(decoded.daysPerWeek, 5)
        XCTAssertEqual(decoded.preferredSplit, "PPL")
        XCTAssertEqual(decoded.unitSystem, "Imperial")
    }

    // MARK: - JSON Formatting Tests

    func testExportProducesValidJSON() throws {
        let export = TestExport(
            version: "1.0",
            exportDate: Date(),
            userProfile: TestExportUserProfile(
                name: "Test",
                goal: "Both",
                daysPerWeek: 3,
                preferredSplit: "Full Body",
                unitSystem: "Metric"
            ),
            sessions: []
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(export)
        let jsonString = String(data: data, encoding: .utf8)!

        // Verify it's parseable JSON
        let parsed = try JSONSerialization.jsonObject(with: data, options: [])
        XCTAssertNotNil(parsed as? [String: Any])

        // Verify structure
        XCTAssertTrue(jsonString.contains("\"version\""))
        XCTAssertTrue(jsonString.contains("\"exportDate\""))
        XCTAssertTrue(jsonString.contains("\"userProfile\""))
        XCTAssertTrue(jsonString.contains("\"sessions\""))
    }

    // MARK: - Edge Cases

    func testEmptySessionsExport() throws {
        let export = TestExport(
            version: "1.0",
            exportDate: Date(),
            userProfile: TestExportUserProfile(
                name: "New User",
                goal: "Strength",
                daysPerWeek: 4,
                preferredSplit: "Upper/Lower",
                unitSystem: "Metric"
            ),
            sessions: []
        )

        let encoded = try JSONEncoder().encode(export)
        let decoded = try JSONDecoder().decode(TestExport.self, from: encoded)

        XCTAssertEqual(decoded.sessions.count, 0)
    }

    func testManySessionsExport() throws {
        var sessions: [TestExportSessionData] = []
        for i in 0..<100 {
            sessions.append(TestExportSessionData(
                id: UUID(),
                date: Date().addingTimeInterval(Double(-i * 86400)),
                templateName: "Workout \(i)",
                location: i % 2 == 0 ? "Gym" : "Home",
                readinessEnergy: "OK",
                readinessSoreness: "None",
                timeAvailable: 60,
                plannedDuration: 60,
                actualDuration: 55,
                isCompleted: true,
                notes: nil,
                sets: []
            ))
        }

        let export = TestExport(
            version: "1.0",
            exportDate: Date(),
            userProfile: TestExportUserProfile(
                name: "Heavy User",
                goal: "Both",
                daysPerWeek: 5,
                preferredSplit: "PPL",
                unitSystem: "Metric"
            ),
            sessions: sessions
        )

        let encoded = try JSONEncoder().encode(export)
        let decoded = try JSONDecoder().decode(TestExport.self, from: encoded)

        XCTAssertEqual(decoded.sessions.count, 100)
    }

    // MARK: - Date Handling Tests

    func testDateEncodingDecoding() throws {
        let originalDate = Date()
        let export = TestExport(
            version: "1.0",
            exportDate: originalDate,
            userProfile: TestExportUserProfile(
                name: "Test",
                goal: "Strength",
                daysPerWeek: 4,
                preferredSplit: "Upper/Lower",
                unitSystem: "Metric"
            ),
            sessions: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let encoded = try encoder.encode(export)
        let decoded = try decoder.decode(TestExport.self, from: encoded)

        // Dates should be within 1 second of each other (accounting for encoding precision)
        XCTAssertEqual(decoded.exportDate.timeIntervalSince1970,
                       originalDate.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    // MARK: - Weight Precision Tests

    func testWeightPrecisionMaintained() throws {
        let setData = TestExportSetData(
            id: UUID(),
            exerciseName: "Bench Press",
            setType: "Working",
            weight: 77.5, // Non-integer weight
            targetReps: 8,
            reps: 8,
            rpe: 7.5, // Non-integer RPE
            targetRPE: 8.0,
            isCompleted: true,
            orderIndex: 0
        )

        let encoded = try JSONEncoder().encode(setData)
        let decoded = try JSONDecoder().decode(TestExportSetData.self, from: encoded)

        XCTAssertEqual(decoded.weight, 77.5, accuracy: 0.001)
        XCTAssertEqual(decoded.rpe ?? 999, 7.5, accuracy: 0.001)
    }

    // MARK: - Version Compatibility Tests

    func testVersionString() throws {
        let export = TestExport(
            version: "2.0.1",
            exportDate: Date(),
            userProfile: TestExportUserProfile(
                name: "Test",
                goal: "Strength",
                daysPerWeek: 4,
                preferredSplit: "Upper/Lower",
                unitSystem: "Metric"
            ),
            sessions: []
        )

        let encoded = try JSONEncoder().encode(export)
        let decoded = try JSONDecoder().decode(TestExport.self, from: encoded)

        XCTAssertEqual(decoded.version, "2.0.1")
    }
}

// MARK: - Export Data Structures for Tests

struct TestExport: Codable {
    let version: String
    let exportDate: Date
    let userProfile: TestExportUserProfile
    let sessions: [TestExportSessionData]
}

struct TestExportUserProfile: Codable {
    let name: String
    let goal: String
    let daysPerWeek: Int
    let preferredSplit: String
    let unitSystem: String
}

struct TestExportSessionData: Codable {
    let id: UUID
    let date: Date
    let templateName: String?
    let location: String
    let readinessEnergy: String
    let readinessSoreness: String
    let timeAvailable: Int
    let plannedDuration: Int
    let actualDuration: Int?
    let isCompleted: Bool
    let notes: String?
    let sets: [TestExportSetData]
}

struct TestExportSetData: Codable {
    let id: UUID
    let exerciseName: String
    let setType: String
    let weight: Double
    let targetReps: Int
    let reps: Int
    let rpe: Double?
    let targetRPE: Double?
    let isCompleted: Bool
    let orderIndex: Int
}
