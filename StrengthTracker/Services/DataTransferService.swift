import Foundation
import SwiftData

// MARK: - Export Data Models

/// Root container for exported data
struct StrengthTrackerExport: Codable {
    let version: String
    let exportedAt: Date
    let profile: ExportedUserProfile?
    let equipment: ExportedEquipmentProfile?
    let workoutSessions: [ExportedWorkoutSession]
    let painFlags: [ExportedPainFlag]
    
    static let currentVersion = "1.0.0"
}

struct ExportedUserProfile: Codable {
    let id: UUID
    let name: String
    let goal: String
    let daysPerWeek: Int
    let preferredSplit: String
    let rpeFamiliarity: Bool
    let defaultRestTime: Int
    let unitSystem: String
    let appearanceMode: String
    let createdAt: Date
    let updatedAt: Date
}

struct ExportedEquipmentProfile: Codable {
    let id: UUID
    let location: String
    let hasBarbell: Bool
    let hasRack: Bool
    let hasBench: Bool
    let hasAdjustableDumbbells: Bool
    let hasCables: Bool
    let hasMachines: Bool
    let hasPullUpBar: Bool
    let hasBands: Bool
    let hasMicroplates: Bool
    let availablePlates: [Double]
    let dumbbellIncrements: [Double]
}

struct ExportedWorkoutSession: Codable {
    let id: UUID
    let date: Date
    let location: String
    let readiness: ExportedReadiness?
    let plannedDuration: Int
    let actualDuration: Int?
    let notes: String?
    let isCompleted: Bool
    let insightText: String?
    let insightAction: String?
    let templateName: String?
    let sets: [ExportedWorkoutSet]
}

struct ExportedReadiness: Codable {
    let energy: String
    let soreness: String
    let timeAvailable: Int
}

struct ExportedWorkoutSet: Codable {
    let id: UUID
    let exerciseName: String
    let exerciseMovementPattern: String
    let setType: String
    let weight: Double
    let targetReps: Int
    let reps: Int
    let rpe: Double?
    let targetRPE: Double?
    let isCompleted: Bool
    let notes: String?
    let timestamp: Date
    let orderIndex: Int
}

struct ExportedPainFlag: Codable {
    let id: UUID
    let exerciseName: String
    let bodyPart: String
    let severity: String
    let notes: String?
    let flaggedDate: Date
    let isResolved: Bool
    let resolvedDate: Date?
}

// MARK: - Import Insights

struct ImportInsights {
    let sessionsImported: Int
    let setsImported: Int
    let newExercisesFound: [String]
    let dateRange: ClosedRange<Date>?
    let totalVolumeImported: Double
    let topExercises: [(name: String, sets: Int)]
    let duplicatesSkipped: Int
    let errors: [String]
    
    var summary: String {
        var lines: [String] = []
        lines.append("✅ Import Complete")
        lines.append("")
        lines.append("📊 **Summary**")
        lines.append("• \(sessionsImported) workout sessions imported")
        lines.append("• \(setsImported) sets logged")
        
        if let range = dateRange {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            lines.append("• Date range: \(formatter.string(from: range.lowerBound)) – \(formatter.string(from: range.upperBound))")
        }
        
        if totalVolumeImported > 0 {
            let volumeString: String
            if totalVolumeImported >= 1000 {
                volumeString = "\(Int(totalVolumeImported / 1000))K kg"
            } else {
                volumeString = "\(Int(totalVolumeImported)) kg"
            }
            lines.append("• Total volume: \(volumeString)")
        }
        
        if !topExercises.isEmpty {
            lines.append("")
            lines.append("🏋️ **Top Exercises Imported**")
            for (name, sets) in topExercises.prefix(5) {
                lines.append("• \(name): \(sets) sets")
            }
        }
        
        if !newExercisesFound.isEmpty {
            lines.append("")
            lines.append("🆕 **New Exercises Found**")
            for name in newExercisesFound.prefix(10) {
                lines.append("• \(name)")
            }
            if newExercisesFound.count > 10 {
                lines.append("• ... and \(newExercisesFound.count - 10) more")
            }
        }
        
        if duplicatesSkipped > 0 {
            lines.append("")
            lines.append("⏭️ \(duplicatesSkipped) duplicate sessions skipped")
        }
        
        if !errors.isEmpty {
            lines.append("")
            lines.append("⚠️ **Warnings**")
            for error in errors.prefix(5) {
                lines.append("• \(error)")
            }
        }
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Data Transfer Service

@MainActor
final class DataTransferService {
    static let shared = DataTransferService()
    private init() {}
    
    // MARK: - Export
    
    func exportData(from context: ModelContext) throws -> Data {
        // Fetch all data
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(profileDescriptor)
        let profile = profiles.first
        
        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let sessions = try context.fetch(sessionDescriptor)
        
        let painFlagDescriptor = FetchDescriptor<PainFlag>()
        let painFlags = try context.fetch(painFlagDescriptor)
        
        // Convert to export models
        let exportedProfile = profile.map { p in
            ExportedUserProfile(
                id: p.id,
                name: p.name,
                goal: p.goal.rawValue,
                daysPerWeek: p.daysPerWeek,
                preferredSplit: p.preferredSplit.rawValue,
                rpeFamiliarity: p.rpeFamiliarity,
                defaultRestTime: p.defaultRestTime,
                unitSystem: p.unitSystem.rawValue,
                appearanceMode: p.appearanceMode.rawValue,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt
            )
        }
        
        let exportedEquipment = profile?.equipmentProfile.map { e in
            ExportedEquipmentProfile(
                id: e.id,
                location: e.location.rawValue,
                hasBarbell: e.hasBarbell,
                hasRack: e.hasRack,
                hasBench: e.hasBench,
                hasAdjustableDumbbells: e.hasAdjustableDumbbells,
                hasCables: e.hasCables,
                hasMachines: e.hasMachines,
                hasPullUpBar: e.hasPullUpBar,
                hasBands: e.hasBands,
                hasMicroplates: e.hasMicroplates,
                availablePlates: e.availablePlates,
                dumbbellIncrements: e.dumbbellIncrements
            )
        }
        
        let exportedSessions = sessions.map { session in
            let readiness = session.readiness
            let exportedReadiness = ExportedReadiness(
                energy: readiness.energy.rawValue,
                soreness: readiness.soreness.rawValue,
                timeAvailable: readiness.timeAvailable
            )
            
            let exportedSets = session.sets.map { set in
                ExportedWorkoutSet(
                    id: set.id,
                    exerciseName: set.exercise?.name ?? "Unknown",
                    exerciseMovementPattern: set.exercise?.movementPattern.rawValue ?? "isolation",
                    setType: set.setType.rawValue,
                    weight: set.weight,
                    targetReps: set.targetReps,
                    reps: set.reps,
                    rpe: set.rpe,
                    targetRPE: set.targetRPE,
                    isCompleted: set.isCompleted,
                    notes: set.notes,
                    timestamp: set.timestamp,
                    orderIndex: set.orderIndex
                )
            }
            
            return ExportedWorkoutSession(
                id: session.id,
                date: session.date,
                location: session.location.rawValue,
                readiness: exportedReadiness,
                plannedDuration: session.plannedDuration,
                actualDuration: session.actualDuration,
                notes: session.notes,
                isCompleted: session.isCompleted,
                insightText: session.insightText,
                insightAction: session.insightAction,
                templateName: session.template?.name,
                sets: exportedSets
            )
        }
        
        let exportedPainFlags = painFlags.map { flag in
            ExportedPainFlag(
                id: flag.id,
                exerciseName: flag.exercise?.name ?? "Unknown",
                bodyPart: flag.bodyPart.rawValue,
                severity: flag.severity.rawValue,
                notes: flag.notes,
                flaggedDate: flag.timestamp,
                isResolved: flag.isResolved,
                resolvedDate: flag.resolvedAt
            )
        }
        
        let exportData = StrengthTrackerExport(
            version: StrengthTrackerExport.currentVersion,
            exportedAt: Date(),
            profile: exportedProfile,
            equipment: exportedEquipment,
            workoutSessions: exportedSessions,
            painFlags: exportedPainFlags
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(exportData)
    }
    
    func exportFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return "StrengthTracker_\(formatter.string(from: Date())).json"
    }
    
    // MARK: - Import
    
    func importData(from data: Data, into context: ModelContext) throws -> ImportInsights {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedData = try decoder.decode(StrengthTrackerExport.self, from: data)
        
        var sessionsImported = 0
        var setsImported = 0
        var newExercisesFound: Set<String> = []
        var dates: [Date] = []
        var totalVolume: Double = 0
        var exerciseSetCounts: [String: Int] = [:]
        var duplicatesSkipped = 0
        let errors: [String] = []
        
        // Fetch existing data to avoid duplicates
        let existingSessionsDescriptor = FetchDescriptor<WorkoutSession>()
        let existingSessions = try context.fetch(existingSessionsDescriptor)
        let existingSessionIds = Set(existingSessions.map { $0.id })
        
        // Get exercise library for matching
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let existingExercises = try context.fetch(exerciseDescriptor)
        let exercisesByName = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.name.lowercased(), $0) })
        
        // Import workout sessions
        for exportedSession in importedData.workoutSessions {
            // Skip duplicates based on ID
            if existingSessionIds.contains(exportedSession.id) {
                duplicatesSkipped += 1
                continue
            }
            
            // Create readiness
            var readiness = Readiness.default
            if let exportedReadiness = exportedSession.readiness {
                readiness = Readiness(
                    energy: EnergyLevel(rawValue: exportedReadiness.energy) ?? .ok,
                    soreness: SorenessLevel(rawValue: exportedReadiness.soreness) ?? .none,
                    timeAvailable: exportedReadiness.timeAvailable
                )
            }
            
            // Create session
            let session = WorkoutSession(
                id: exportedSession.id,
                date: exportedSession.date,
                location: Location(rawValue: exportedSession.location) ?? .gym,
                readiness: readiness,
                plannedDuration: exportedSession.plannedDuration,
                actualDuration: exportedSession.actualDuration,
                notes: exportedSession.notes,
                isCompleted: exportedSession.isCompleted
            )
            session.insightText = exportedSession.insightText
            session.insightAction = exportedSession.insightAction
            
            context.insert(session)
            
            // Import sets
            for exportedSet in exportedSession.sets {
                // Find or note exercise
                let exercise = exercisesByName[exportedSet.exerciseName.lowercased()]
                if exercise == nil {
                    newExercisesFound.insert(exportedSet.exerciseName)
                }
                
                let workoutSet = WorkoutSet(
                    id: exportedSet.id,
                    exercise: exercise,
                    setType: SetType(rawValue: exportedSet.setType) ?? .working,
                    weight: exportedSet.weight,
                    targetReps: exportedSet.targetReps,
                    reps: exportedSet.reps,
                    rpe: exportedSet.rpe,
                    targetRPE: exportedSet.targetRPE,
                    isCompleted: exportedSet.isCompleted,
                    notes: exportedSet.notes,
                    timestamp: exportedSet.timestamp,
                    orderIndex: exportedSet.orderIndex
                )
                
                workoutSet.session = session
                context.insert(workoutSet)
                
                setsImported += 1
                
                if exportedSet.isCompleted {
                    totalVolume += exportedSet.weight * Double(exportedSet.reps)
                    exerciseSetCounts[exportedSet.exerciseName, default: 0] += 1
                }
            }
            
            dates.append(exportedSession.date)
            sessionsImported += 1
        }
        
        // Calculate date range
        let dateRange: ClosedRange<Date>? = dates.isEmpty ? nil : dates.min()!...dates.max()!
        
        // Calculate top exercises
        let topExercises = exerciseSetCounts
            .sorted { $0.value > $1.value }
            .map { (name: $0.key, sets: $0.value) }
        
        try context.save()
        
        return ImportInsights(
            sessionsImported: sessionsImported,
            setsImported: setsImported,
            newExercisesFound: Array(newExercisesFound).sorted(),
            dateRange: dateRange,
            totalVolumeImported: totalVolume,
            topExercises: topExercises,
            duplicatesSkipped: duplicatesSkipped,
            errors: errors
        )
    }
    
    // MARK: - Validation
    
    func validateImportData(_ data: Data) throws -> (version: String, sessionCount: Int, dateRange: String) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedData = try decoder.decode(StrengthTrackerExport.self, from: data)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let dates = importedData.workoutSessions.map { $0.date }
        let dateRangeStr: String
        if let minDate = dates.min(), let maxDate = dates.max() {
            dateRangeStr = "\(formatter.string(from: minDate)) – \(formatter.string(from: maxDate))"
        } else {
            dateRangeStr = "No sessions"
        }
        
        return (
            version: importedData.version,
            sessionCount: importedData.workoutSessions.count,
            dateRange: dateRangeStr
        )
    }
}
