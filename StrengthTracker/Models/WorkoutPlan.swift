import Foundation
import SwiftData

/// Represents a multi-week workout plan/program
@Model
final class WorkoutPlan {
    var id: UUID
    var name: String
    var planDescription: String?
    var durationWeeks: Int
    var currentWeek: Int
    var isActive: Bool
    var startDate: Date?
    var completedWorkoutsThisWeek: Int
    var workoutsPerWeek: Int
    var goal: Goal
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \PlanWeek.plan) var weeks: [PlanWeek]
    
    init(
        id: UUID = UUID(),
        name: String,
        planDescription: String? = nil,
        durationWeeks: Int = 4,
        currentWeek: Int = 1,
        isActive: Bool = false,
        startDate: Date? = nil,
        completedWorkoutsThisWeek: Int = 0,
        workoutsPerWeek: Int = 4,
        goal: Goal = .both,
        weeks: [PlanWeek] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.planDescription = planDescription
        self.durationWeeks = durationWeeks
        self.currentWeek = currentWeek
        self.isActive = isActive
        self.startDate = startDate
        self.completedWorkoutsThisWeek = completedWorkoutsThisWeek
        self.workoutsPerWeek = workoutsPerWeek
        self.goal = goal
        self.weeks = weeks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var sortedWeeks: [PlanWeek] {
        weeks.sorted { $0.weekNumber < $1.weekNumber }
    }
    
    var currentPlanWeek: PlanWeek? {
        weeks.first { $0.weekNumber == currentWeek }
    }
    
    var completedWeeks: Int {
        weeks.filter { $0.isCompleted }.count
    }
    
    var progressPercentage: Double {
        guard durationWeeks > 0 else { return 0 }
        let weekProgress = Double(completedWeeks) / Double(durationWeeks)
        let currentWeekProgress = Double(completedWorkoutsThisWeek) / Double(max(1, workoutsPerWeek)) / Double(durationWeeks)
        return min(1.0, weekProgress + currentWeekProgress)
    }
    
    var isCompleted: Bool {
        completedWeeks >= durationWeeks
    }
    
    var remainingWeeks: Int {
        max(0, durationWeeks - currentWeek + 1)
    }
    
    var estimatedEndDate: Date? {
        guard let start = startDate else { return nil }
        return Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: start)
    }
    
    var statusText: String {
        if isCompleted {
            return "Completed"
        } else if isActive {
            return "Week \(currentWeek) of \(durationWeeks)"
        } else if startDate != nil {
            return "Paused at Week \(currentWeek)"
        } else {
            return "\(durationWeeks) weeks • Not started"
        }
    }
    
    // MARK: - Methods
    
    /// Activate this plan and deactivate all others
    func activate(in context: ModelContext) {
        // Deactivate all other plans
        let descriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        
        if let activePlans = try? context.fetch(descriptor) {
            for plan in activePlans {
                plan.isActive = false
            }
        }
        
        // Activate this plan
        self.isActive = true
        self.startDate = self.startDate ?? Date()
        self.updatedAt = Date()
    }
    
    /// Advance to the next week if current week is complete
    func advanceWeekIfNeeded() {
        guard isActive else { return }
        guard completedWorkoutsThisWeek >= workoutsPerWeek else { return }
        
        // Mark current week as completed
        currentPlanWeek?.isCompleted = true
        
        // Advance or complete plan
        if currentWeek < durationWeeks {
            currentWeek += 1
            completedWorkoutsThisWeek = 0
        } else {
            // Plan completed
            isActive = false
        }
        
        updatedAt = Date()
    }
    
    /// Record a completed workout and check for week advancement
    func recordCompletedWorkout() {
        guard isActive else { return }
        completedWorkoutsThisWeek += 1
        advanceWeekIfNeeded()
    }
}
