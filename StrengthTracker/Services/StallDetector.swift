import Foundation
import SwiftData

/// Dedicated service for detecting workout stalls and suggesting fixes
actor StallDetector {
    static let shared = StallDetector()
    
    private init() {}
    
    /// Minimum sessions required for stall detection
    private let minimumSessions = 3
    
    /// Threshold for e1RM improvement to not be considered stalled (percentage)
    private let improvementThreshold = 1.0 // 1%
    
    // MARK: - Stall Detection
    
    /// Analyze if an exercise is stalled based on recent workout history
    func detectStall(
        exerciseName: String,
        sessions: [WorkoutSession]
    ) -> StallAnalysisResponse {
        // Extract sets for this exercise from recent sessions
        let exerciseSessions = sessions.compactMap { session -> ExerciseSessionData? in
            let sets = session.sets.filter({ $0.exercise?.name == exerciseName })
            guard !sets.isEmpty else { return nil }
            
            // Find top set (highest e1RM)
            let topSet = sets.max(by: { $0.e1RM < $1.e1RM })
            
            return ExerciseSessionData(
                date: session.date,
                topSetWeight: topSet?.weight ?? 0,
                topSetReps: topSet?.reps ?? 0,
                topSetRPE: topSet?.rpe,
                e1RM: topSet?.e1RM ?? 0
            )
        }.prefix(minimumSessions)
        
        guard exerciseSessions.count >= minimumSessions else {
            return StallAnalysisResponse(
                isStalled: false,
                reason: nil,
                suggestedFix: nil,
                fixType: nil,
                details: "Need \(minimumSessions) sessions for stall detection"
            )
        }
        
        return analyzeSessionData(Array(exerciseSessions), exerciseName: exerciseName)
    }
    
    /// Analyze stall from context (used by LLM service)
    func analyzeStall(context: StallContext) -> StallAnalysisResponse {
        guard context.lastSessions.count >= minimumSessions else {
            return StallAnalysisResponse(
                isStalled: false,
                reason: nil,
                suggestedFix: nil,
                fixType: nil,
                details: nil
            )
        }
        
        let sessionData = context.lastSessions.map { session in
            ExerciseSessionData(
                date: Date(), // Not used for analysis
                topSetWeight: session.topSetWeight,
                topSetReps: session.topSetReps,
                topSetRPE: session.topSetRPE,
                e1RM: session.e1RM
            )
        }
        
        return analyzeSessionData(sessionData, exerciseName: context.exerciseName)
    }
    
    // MARK: - Analysis Logic
    
    private func analyzeSessionData(
        _ sessions: [ExerciseSessionData],
        exerciseName: String
    ) -> StallAnalysisResponse {
        let e1RMs = sessions.map { $0.e1RM }
        let newestE1RM = e1RMs.first ?? 0
        let oldestE1RM = e1RMs.last ?? 0
        let maxE1RM = e1RMs.max() ?? 0
        
        // Calculate improvement
        let improvement = oldestE1RM > 0 ? ((newestE1RM - oldestE1RM) / oldestE1RM) * 100 : 0
        
        // Not stalled if showing improvement
        if improvement >= improvementThreshold {
            return StallAnalysisResponse(
                isStalled: false,
                reason: nil,
                suggestedFix: nil,
                fixType: nil,
                details: "\(exerciseName) progressing well (+\(String(format: "%.1f", improvement))%)"
            )
        }
        
        // Determine the type of stall and appropriate fix
        return determineFix(
            sessions: sessions,
            exerciseName: exerciseName,
            maxE1RM: maxE1RM
        )
    }
    
    private func determineFix(
        sessions: [ExerciseSessionData],
        exerciseName: String,
        maxE1RM: Double
    ) -> StallAnalysisResponse {
        // Calculate averages
        let rpeValues = sessions.compactMap { $0.topSetRPE }
        let avgRPE = rpeValues.isEmpty ? 8.0 : rpeValues.reduce(0, +) / Double(rpeValues.count)
        let avgReps = sessions.map { $0.topSetReps }.reduce(0, +) / sessions.count
        
        // High RPE stall - needs deload
        if avgRPE >= 9.0 {
            let deloadWeight = maxE1RM * 0.92 // 8% reduction
            return StallAnalysisResponse(
                isStalled: true,
                reason: "RPE consistently high (\(String(format: "%.1f", avgRPE))) with no progress for \(sessions.count) sessions",
                suggestedFix: "Take a micro-deload: reduce \(exerciseName) weight by 8% for one week",
                fixType: StallFix.deload.rawValue,
                details: "Target: \(String(format: "%.1f", deloadWeight))kg. Focus on technique and bar speed."
            )
        }
        
        // Low rep stall - needs rep range change
        if avgReps <= 4 {
            return StallAnalysisResponse(
                isStalled: true,
                reason: "Stuck in low rep range (\(avgReps) avg) with no weight increases for \(sessions.count) sessions",
                suggestedFix: "Switch \(exerciseName) to higher rep range (6-8) to build volume",
                fixType: StallFix.repRange.rawValue,
                details: "Use ~85% of current weight. Focus on 6-8 reps for 2-3 weeks, then return to lower reps."
            )
        }
        
        // Mid-rep stall - needs variation
        if avgReps >= 5 && avgReps <= 8 {
            let variations = getVariationSuggestions(for: exerciseName)
            return StallAnalysisResponse(
                isStalled: true,
                reason: "No e1RM improvement in \(sessions.count) sessions despite moderate RPE (\(String(format: "%.1f", avgRPE)))",
                suggestedFix: "Try a variation of \(exerciseName) for 3-4 weeks",
                fixType: StallFix.variation.rawValue,
                details: variations.isEmpty
                    ? "Swap to a similar movement pattern to break through plateau"
                    : "Suggested: \(variations.joined(separator: ", "))"
            )
        }
        
        // High rep stall - needs weight increase
        return StallAnalysisResponse(
            isStalled: true,
            reason: "Rep count high (\(avgReps) avg) but weight not increasing for \(sessions.count) sessions",
            suggestedFix: "Force a weight increase on \(exerciseName), even if reps drop",
            fixType: StallFix.weightJump.rawValue,
            details: "Add 2.5-5kg and accept fewer reps initially. Rebuild from there."
        )
    }
    
    // MARK: - Variation Suggestions
    
    private func getVariationSuggestions(for exerciseName: String) -> [String] {
        let variationMap: [String: [String]] = [
            "Bench Press": ["Close Grip Bench", "Incline Bench Press", "Dumbbell Bench Press"],
            "Barbell Squat": ["Front Squat", "Pause Squat", "Box Squat"],
            "Deadlift": ["Deficit Deadlift", "Pause Deadlift", "Romanian Deadlift"],
            "Overhead Press": ["Push Press", "Seated Press", "Dumbbell Shoulder Press"],
            "Barbell Row": ["Pendlay Row", "Chest Supported Row", "T-Bar Row"],
            "Pull-ups": ["Weighted Pull-ups", "Wide Grip Pull-ups", "Chin-ups"]
        ]
        
        return variationMap[exerciseName] ?? []
    }
    
    // MARK: - Batch Analysis
    
    /// Analyze all exercises for potential stalls
    func analyzeAllExercises(
        sessions: [WorkoutSession]
    ) -> [String: StallAnalysisResponse] {
        // Get unique exercise names from recent sessions
        var exerciseNames = Set<String>()
        for session in sessions {
            for set in session.sets {
                if let name = set.exercise?.name {
                    exerciseNames.insert(name)
                }
            }
        }
        
        // Analyze each exercise
        var results: [String: StallAnalysisResponse] = [:]
        for name in exerciseNames {
            results[name] = detectStall(exerciseName: name, sessions: sessions)
        }
        
        return results
    }
    
    /// Get exercises that are currently stalled
    func getStalledExercises(sessions: [WorkoutSession]) -> [String] {
        let analysis = analyzeAllExercises(sessions: sessions)
        return analysis.filter { $0.value.isStalled }.map { $0.key }
    }
}

// MARK: - Supporting Types

enum StallFix: String, Codable, CaseIterable {
    case deload = "deload"
    case repRange = "rep_range"
    case variation = "variation"
    case weightJump = "weight_jump"
    
    var displayName: String {
        switch self {
        case .deload: return "Deload Week"
        case .repRange: return "Change Rep Range"
        case .variation: return "Switch Variation"
        case .weightJump: return "Force Weight Increase"
        }
    }
    
    var icon: String {
        switch self {
        case .deload: return "arrow.down.circle"
        case .repRange: return "number.circle"
        case .variation: return "arrow.triangle.swap"
        case .weightJump: return "arrow.up.circle"
        }
    }
}

private struct ExerciseSessionData {
    let date: Date
    let topSetWeight: Double
    let topSetReps: Int
    let topSetRPE: Double?
    let e1RM: Double
}
