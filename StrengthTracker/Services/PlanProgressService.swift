import Foundation
import SwiftData

/// Service for managing workout plan progress and auto-advancement
class PlanProgressService {
    static let shared = PlanProgressService()
    
    private init() {}
    
    // MARK: - Week Advancement
    
    /// Called when a workout is completed to update plan progress
    func recordCompletedWorkout(
        session: WorkoutSession,
        in context: ModelContext
    ) {
        // Find active plan
        guard let activePlan = getActivePlan(in: context) else { return }
        
        // Update progress
        activePlan.recordCompletedWorkout()
        
        // Check if week advanced and notify if needed
        try? context.save()
    }
    
    /// Get the currently active workout plan
    func getActivePlan(in context: ModelContext) -> WorkoutPlan? {
        let descriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        return try? context.fetch(descriptor).first
    }
    
    /// Get the current week's templates for the active plan
    func getCurrentWeekTemplates(in context: ModelContext) -> [WorkoutTemplate] {
        guard let activePlan = getActivePlan(in: context),
              let currentWeek = activePlan.currentPlanWeek else {
            return []
        }
        return currentWeek.sortedTemplates
    }
    
    /// Get the next workout template to perform
    func getNextWorkout(
        in context: ModelContext,
        recentSessions: [WorkoutSession]
    ) -> WorkoutTemplate? {
        guard let activePlan = getActivePlan(in: context),
              let currentWeek = activePlan.currentPlanWeek else {
            return nil
        }
        
        let templates = currentWeek.sortedTemplates
        guard !templates.isEmpty else { return nil }
        
        // Find the most recent workout in this week
        let weekStartDate = getWeekStartDate(for: activePlan)
        let thisWeekSessions = recentSessions.filter { session in
            guard let date = session.date as Date? else { return false }
            return date >= weekStartDate
        }
        
        // Find the last template used
        if let lastSession = thisWeekSessions.first,
           let lastTemplate = lastSession.template,
           let lastIndex = templates.firstIndex(where: { $0.id == lastTemplate.id }) {
            // Return next template in sequence
            let nextIndex = (lastIndex + 1) % templates.count
            return templates[nextIndex]
        }
        
        // Return first template if no sessions this week
        return templates.first
    }
    
    // MARK: - Week Calculations
    
    /// Calculate the start date of the current week in the plan
    func getWeekStartDate(for plan: WorkoutPlan) -> Date {
        guard let startDate = plan.startDate else { return Date() }
        
        let weeksElapsed = plan.currentWeek - 1
        return Calendar.current.date(
            byAdding: .weekOfYear,
            value: weeksElapsed,
            to: startDate
        ) ?? startDate
    }
    
    /// Get workouts remaining in the current week
    func getWorkoutsRemainingThisWeek(for plan: WorkoutPlan) -> Int {
        return max(0, plan.workoutsPerWeek - plan.completedWorkoutsThisWeek)
    }
    
    // MARK: - Modifiers
    
    /// Get the intensity modifier for the current week
    func getCurrentIntensityModifier(in context: ModelContext) -> Double {
        guard let activePlan = getActivePlan(in: context),
              let currentWeek = activePlan.currentPlanWeek else {
            return 1.0
        }
        return currentWeek.intensityModifier
    }
    
    /// Get the volume modifier for the current week
    func getCurrentVolumeModifier(in context: ModelContext) -> Double {
        guard let activePlan = getActivePlan(in: context),
              let currentWeek = activePlan.currentPlanWeek else {
            return 1.0
        }
        return currentWeek.volumeModifier
    }
    
    /// Apply current week modifiers to a weight
    func adjustWeight(_ weight: Double, in context: ModelContext) -> Double {
        let modifier = getCurrentIntensityModifier(in: context)
        return weight * modifier
    }
    
    /// Apply current week modifiers to a prescription
    func adjustPrescription(
        _ prescription: Prescription,
        in context: ModelContext
    ) -> Prescription {
        guard let activePlan = getActivePlan(in: context),
              let currentWeek = activePlan.currentPlanWeek else {
            return prescription
        }
        return currentWeek.applyModifiers(to: prescription)
    }
    
    // MARK: - Plan Management
    
    /// Activate a plan and deactivate others
    func activatePlan(_ plan: WorkoutPlan, in context: ModelContext) {
        plan.activate(in: context)
        try? context.save()
    }
    
    /// Deactivate the current plan
    func deactivateCurrentPlan(in context: ModelContext) {
        guard let activePlan = getActivePlan(in: context) else { return }
        activePlan.isActive = false
        try? context.save()
    }
    
    /// Skip to a specific week in a plan
    func skipToWeek(_ weekNumber: Int, for plan: WorkoutPlan, in context: ModelContext) {
        guard weekNumber >= 1 && weekNumber <= plan.durationWeeks else { return }
        
        // Mark previous weeks as completed
        for week in plan.weeks where week.weekNumber < weekNumber {
            week.isCompleted = true
        }
        
        plan.currentWeek = weekNumber
        plan.completedWorkoutsThisWeek = 0
        plan.updatedAt = Date()
        
        try? context.save()
    }
    
    /// Reset plan progress
    func resetPlan(_ plan: WorkoutPlan, in context: ModelContext) {
        plan.currentWeek = 1
        plan.completedWorkoutsThisWeek = 0
        plan.startDate = nil
        plan.isActive = false
        
        for week in plan.weeks {
            week.isCompleted = false
        }
        
        plan.updatedAt = Date()
        try? context.save()
    }
}
