import Foundation
import SwiftData

/// Represents a single week within a workout plan
@Model
final class PlanWeek {
    var id: UUID
    var weekNumber: Int
    var weekTypeRaw: String
    var intensityModifier: Double
    var volumeModifier: Double
    var notes: String?
    var isCompleted: Bool
    
    @Relationship var plan: WorkoutPlan?
    @Relationship var templates: [WorkoutTemplate]
    
    init(
        id: UUID = UUID(),
        weekNumber: Int,
        weekType: WeekType = .regular,
        intensityModifier: Double? = nil,
        volumeModifier: Double? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        templates: [WorkoutTemplate] = []
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.weekTypeRaw = weekType.rawValue
        // Use week type defaults if not explicitly provided
        self.intensityModifier = intensityModifier ?? weekType.intensityModifier
        self.volumeModifier = volumeModifier ?? weekType.volumeModifier
        self.notes = notes ?? weekType.coachingNotes
        self.isCompleted = isCompleted
        self.templates = templates
    }
    
    // MARK: - Week Type
    
    var weekType: WeekType {
        get { WeekType(rawValue: weekTypeRaw) ?? .regular }
        set { weekTypeRaw = newValue.rawValue }
    }
    
    // MARK: - Computed Properties
    
    var sortedTemplates: [WorkoutTemplate] {
        templates.sorted { $0.dayNumber < $1.dayNumber }
    }
    
    var workoutCount: Int {
        templates.count
    }
    
    var totalDuration: Int {
        templates.reduce(0) { $0 + $1.targetDuration }
    }
    
    var weekLabel: String {
        "Week \(weekNumber)"
    }
    
    var summaryText: String {
        let templateNames = sortedTemplates.map { $0.name }.joined(separator: ", ")
        if templateNames.isEmpty {
            return "No workouts assigned"
        }
        return templateNames
    }
    
    var statusIcon: String {
        if isCompleted {
            return "checkmark.circle.fill"
        } else if let plan = plan, plan.currentWeek == weekNumber && plan.isActive {
            return "circle.fill"
        } else {
            return "circle"
        }
    }
    
    var statusColor: String {
        if isCompleted {
            return "green"
        } else if let plan = plan, plan.currentWeek == weekNumber && plan.isActive {
            return "blue"
        } else {
            return "gray"
        }
    }
    
    // MARK: - Methods
    
    /// Apply week modifiers to a prescription
    func applyModifiers(to prescription: Prescription) -> Prescription {
        var modified = prescription
        
        // Apply RPE cap based on week type
        modified.topSetRPECap = min(weekType.rpeCap, prescription.topSetRPECap)
        
        // Apply volume modifier to sets
        if weekType == .deload || weekType == .test {
            modified.backoffSets = max(1, Int(Double(prescription.backoffSets) * volumeModifier))
            modified.workingSets = max(1, Int(Double(prescription.workingSets) * volumeModifier))
        }
        
        return modified
    }
    
    /// Calculate weight with intensity modifier applied
    func adjustedWeight(baseWeight: Double) -> Double {
        return baseWeight * intensityModifier
    }
}
