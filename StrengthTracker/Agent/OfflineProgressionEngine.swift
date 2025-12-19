import Foundation

/// Rule-based progression engine for offline/fallback mode
actor OfflineProgressionEngine {

    func generatePlan(context: CoachContext) async -> TodayPlanResponse {
        var exercises: [PlannedExerciseResponse] = []
        var adjustments: [String] = []
        var reasoning: [String] = []
        var substitutions: [SubstitutionResponse] = []

        let readiness = Readiness(
            energy: EnergyLevel(rawValue: context.readiness.energy) ?? .ok,
            soreness: SorenessLevel(rawValue: context.readiness.soreness) ?? .none,
            timeAvailable: context.timeAvailable
        )

        // Apply readiness adjustments
        if readiness.shouldReduceIntensity {
            adjustments.append("Reduced intensity due to \(context.readiness.energy) energy / \(context.readiness.soreness) soreness")
        }

        // Build pain awareness context
        let painBodyParts = Set(context.painFlags.map { $0.bodyPart })
        if !painBodyParts.isEmpty {
            adjustments.append("Pain-aware plan: avoiding exercises targeting \(painBodyParts.joined(separator: ", "))")
        }

        for templateExercise in context.currentTemplate.exercises {
            // Skip optional exercises if time constrained
            if templateExercise.isOptional && context.timeAvailable <= 45 {
                reasoning.append("Skipped optional \(templateExercise.name) due to time constraint")
                continue
            }

            // Check if this exercise needs substitution due to pain
            let exerciseNeedsSubstitution = checkIfNeedsSubstitution(
                exerciseName: templateExercise.name,
                painFlags: context.painFlags
            )

            var exerciseToUse = templateExercise.name
            var historyToUse = context.recentHistory.first { $0.exerciseName == templateExercise.name }

            if let (substitute, reason) = exerciseNeedsSubstitution {
                substitutions.append(SubstitutionResponse(
                    from: templateExercise.name,
                    to: substitute,
                    reason: reason
                ))
                exerciseToUse = substitute
                historyToUse = context.recentHistory.first { $0.exerciseName == substitute }
                reasoning.append("Substituted \(templateExercise.name) → \(substitute) due to pain")
            }

            let plannedExercise = planExercise(
                name: exerciseToUse,
                prescription: templateExercise.prescription,
                history: historyToUse,
                readiness: readiness
            )

            exercises.append(plannedExercise)

            if let lastSession = historyToUse?.lastSessions.first {
                reasoning.append("\(exerciseToUse): Last \(lastSession.topSetWeight)kg x \(lastSession.topSetReps)")
            }
        }

        let estimatedDuration = calculateDuration(exercises: exercises)

        return TodayPlanResponse(
            exercises: exercises,
            substitutions: substitutions,
            adjustments: adjustments,
            reasoning: reasoning,
            estimatedDuration: estimatedDuration
        )
    }

    private func planExercise(
        name: String,
        prescription: PrescriptionContext,
        history: ExerciseHistoryContext?,
        readiness: Readiness
    ) -> PlannedExerciseResponse {
        // Determine top set target
        let (topSetWeight, topSetReps) = calculateTopSetTarget(
            prescription: prescription,
            history: history,
            readiness: readiness
        )

        // Adjust RPE cap based on readiness
        var rpeCap = prescription.topSetRPECap
        if readiness.shouldReduceIntensity {
            rpeCap = min(rpeCap, 7.5)
        } else if readiness.shouldIncreaseIntensity {
            rpeCap = min(rpeCap + 0.5, 9.5)
        }

        // Generate warmup sets
        let warmupSets = generateWarmups(topSetWeight: topSetWeight)

        // Generate backoff sets
        var backoffSets: [PlannedSetResponse] = []
        if prescription.progressionType == "Top Set + Backoffs" && prescription.backoffSets > 0 {
            let backoffWeight = topSetWeight * (1 - prescription.backoffLoadDropPercent)
            let backoffReps = parseRepsRange(prescription.backoffRepsRange).0 // Min of range

            var numBackoffs = prescription.backoffSets
            if readiness.shouldReduceIntensity {
                numBackoffs = max(1, numBackoffs - 1)
            } else if readiness.shouldIncreaseIntensity {
                numBackoffs += 1
            }

            backoffSets = [PlannedSetResponse(
                weight: roundToNearest(backoffWeight, increment: 2.5),
                reps: backoffReps,
                rpeCap: rpeCap,
                setCount: numBackoffs
            )]
        }

        // Generate working sets for double progression
        var workingSets: [PlannedSetResponse] = []
        if prescription.progressionType == "Double Progression" {
            let (minReps, _) = parseRepsRange(prescription.topSetRepsRange)
            workingSets = [PlannedSetResponse(
                weight: topSetWeight,
                reps: minReps,
                rpeCap: rpeCap,
                setCount: 3 // Default working sets
            )]
        }

        // Top set only for Top Set + Backoffs progression
        let topSet: PlannedSetResponse? = prescription.progressionType == "Top Set + Backoffs"
            ? PlannedSetResponse(
                weight: topSetWeight,
                reps: topSetReps,
                rpeCap: rpeCap,
                setCount: 1
            )
            : nil

        return PlannedExerciseResponse(
            exerciseName: name,
            warmupSets: warmupSets,
            topSet: topSet,
            backoffSets: backoffSets,
            workingSets: workingSets
        )
    }

    private func calculateTopSetTarget(
        prescription: PrescriptionContext,
        history: ExerciseHistoryContext?,
        readiness: Readiness
    ) -> (weight: Double, reps: Int) {
        let (minReps, maxReps) = parseRepsRange(prescription.topSetRepsRange)

        // No history - start conservative
        guard let history = history, let lastSession = history.lastSessions.first else {
            return (20.0, minReps) // Default starting weight
        }

        let lastWeight = lastSession.topSetWeight
        let lastReps = lastSession.topSetReps
        let lastRPE = lastSession.topSetRPE ?? 8.0

        // Progression logic
        if lastReps >= maxReps && lastRPE <= prescription.topSetRPECap {
            // Hit top of rep range at/below RPE cap -> increase weight
            let increment = lastWeight >= 100 ? 2.5 : 2.5 // Standard increment
            return (lastWeight + increment, minReps)
        } else if lastReps < minReps || lastRPE > prescription.topSetRPECap + 0.5 {
            // Struggling - keep weight, maybe reduce
            if readiness.shouldReduceIntensity {
                return (lastWeight * 0.95, minReps)
            }
            return (lastWeight, minReps)
        } else {
            // In range - try to add a rep
            let targetReps = min(lastReps + 1, maxReps)
            return (lastWeight, targetReps)
        }
    }

    private func generateWarmups(topSetWeight: Double) -> [PlannedSetResponse] {
        guard topSetWeight > 20 else {
            return []
        }

        var warmups: [PlannedSetResponse] = []
        let barWeight = 20.0

        // Empty bar
        if topSetWeight > barWeight * 1.5 {
            warmups.append(PlannedSetResponse(weight: barWeight, reps: 10, rpeCap: 5, setCount: 1))
        }

        // Progressive warmups
        let percentages = [0.4, 0.6, 0.8]
        for percentage in percentages {
            let weight = topSetWeight * percentage
            if weight > barWeight {
                let reps = percentage < 0.7 ? 5 : 3
                warmups.append(PlannedSetResponse(
                    weight: roundToNearest(weight, increment: 2.5),
                    reps: reps,
                    rpeCap: 6,
                    setCount: 1
                ))
            }
        }

        return warmups
    }

    private func calculateDuration(exercises: [PlannedExerciseResponse]) -> Int {
        var totalSets = 0

        for exercise in exercises {
            totalSets += exercise.warmupSets.reduce(0) { $0 + $1.setCount }
            totalSets += exercise.topSet?.setCount ?? 0
            totalSets += exercise.backoffSets.reduce(0) { $0 + $1.setCount }
            totalSets += exercise.workingSets.reduce(0) { $0 + $1.setCount }
        }

        // Assume 3 minutes per set (including rest)
        return totalSets * 3
    }

    func generateInsight(session: SessionSummary) async -> InsightResponse {
        var insights: [(insight: String, action: String, category: String)] = []

        for exercise in session.exercises {
            if let prevE1RM = exercise.previousE1RM, exercise.e1RM > prevE1RM {
                let improvement = ((exercise.e1RM - prevE1RM) / prevE1RM) * 100
                insights.append((
                    insight: "\(exercise.name) e1RM improved by \(String(format: "%.1f", improvement))%",
                    action: "Keep current progression, add weight next session",
                    category: "progress"
                ))
            }

            if !exercise.targetHit {
                insights.append((
                    insight: "\(exercise.name) missed rep target",
                    action: "Keep weight the same, focus on hitting target reps next time",
                    category: "fatigue"
                ))
            }
        }

        // Default insight
        if insights.isEmpty {
            return InsightResponse(
                insight: "Solid workout completed",
                action: "Continue current program, small weight increases where possible",
                category: "progress"
            )
        }

        // Return most relevant insight
        let best = insights.first!
        return InsightResponse(
            insight: best.insight,
            action: best.action,
            category: best.category
        )
    }

    func analyzeStall(context: StallContext) async -> StallAnalysisResponse {
        guard context.lastSessions.count >= 3 else {
            return StallAnalysisResponse(
                isStalled: false,
                reason: nil,
                suggestedFix: nil,
                fixType: nil,
                details: nil
            )
        }

        let e1RMs = context.lastSessions.map { $0.e1RM }
        let maxE1RM = e1RMs.max() ?? 0
        let oldestE1RM = e1RMs.last ?? 0

        // Check for stall (no improvement)
        if maxE1RM <= oldestE1RM {
            // Determine fix based on average RPE
            let avgRPE = context.lastSessions.compactMap { $0.topSetRPE }.reduce(0, +) /
                         Double(context.lastSessions.compactMap { $0.topSetRPE }.count)

            if avgRPE >= 9.0 {
                return StallAnalysisResponse(
                    isStalled: true,
                    reason: "RPE consistently high (\(String(format: "%.1f", avgRPE))) with no progress",
                    suggestedFix: "Take a micro-deload: reduce weight by 8% for one week",
                    fixType: "deload",
                    details: "New target: \(String(format: "%.1f", maxE1RM * 0.92))kg"
                )
            }

            let avgReps = context.lastSessions.map { $0.topSetReps }.reduce(0, +) / context.lastSessions.count

            if avgReps <= 4 {
                return StallAnalysisResponse(
                    isStalled: true,
                    reason: "Stuck in low rep range with no weight increases",
                    suggestedFix: "Switch to higher rep range (6-8) to build volume",
                    fixType: "rep_range",
                    details: "Try 6-8 reps for 2-3 weeks before returning to lower reps"
                )
            }

            return StallAnalysisResponse(
                isStalled: true,
                reason: "No e1RM improvement in 3 sessions",
                suggestedFix: "Try a variation of this exercise for 3-4 weeks",
                fixType: "variation",
                details: "Swap to a similar movement pattern to break through plateau"
            )
        }

        return StallAnalysisResponse(
            isStalled: false,
            reason: nil,
            suggestedFix: nil,
            fixType: nil,
            details: nil
        )
    }

    // MARK: - Helpers

    private func parseRepsRange(_ range: String) -> (min: Int, max: Int) {
        let parts = range.split(separator: "-")
        guard parts.count == 2,
              let min = Int(parts[0]),
              let max = Int(parts[1]) else {
            return (5, 8) // Default
        }
        return (min, max)
    }

    private func roundToNearest(_ value: Double, increment: Double) -> Double {
        return (value / increment).rounded() * increment
    }

    /// Check if an exercise needs substitution based on pain flags
    /// Returns (substitute name, reason) if substitution needed, nil otherwise
    func checkIfNeedsSubstitution(
        exerciseName: String,
        painFlags: [PainFlagContext]
    ) -> (substitute: String, reason: String)? {
        // Map of exercises to their primary body parts
        let exerciseBodyParts: [String: [String]] = [
            // Horizontal Push
            "Bench Press": ["chest", "shoulders", "arms"],
            "Incline Bench Press": ["chest", "shoulders", "arms"],
            "Dumbbell Bench Press": ["chest", "shoulders", "arms"],
            "Floor Press": ["chest", "arms"],
            "Push-ups": ["chest", "shoulders", "arms"],
            "Dips": ["chest", "shoulders", "arms"],
            "Machine Chest Press": ["chest", "shoulders", "arms"],

            // Vertical Push
            "Overhead Press": ["shoulders", "arms"],
            "Dumbbell Shoulder Press": ["shoulders", "arms"],

            // Vertical Pull
            "Pull-ups": ["back", "arms"],
            "Chin-ups": ["back", "arms"],
            "Lat Pulldown": ["back", "arms"],
            "Banded Pull-ups": ["back", "arms"],

            // Horizontal Pull
            "Barbell Row": ["back", "arms"],
            "Dumbbell Row": ["back", "arms"],
            "Chest Supported Row": ["back", "arms"],
            "Cable Row": ["back", "arms"],
            "Inverted Row": ["back", "arms"],

            // Squat Pattern
            "Barbell Squat": ["legs"],
            "Front Squat": ["legs", "core"],
            "Goblet Squat": ["legs"],
            "Leg Press": ["legs"],
            "Hack Squat": ["legs"],

            // Hinge Pattern
            "Deadlift": ["back", "legs"],
            "Romanian Deadlift": ["back", "legs"],
            "Dumbbell Romanian Deadlift": ["back", "legs"],

            // Lunge Pattern
            "Bulgarian Split Squat": ["legs"],
            "Walking Lunges": ["legs"],

            // Arms
            "Barbell Curl": ["arms"],
            "Dumbbell Curl": ["arms"],
            "Cable Curl": ["arms"],
            "Band Curl": ["arms"],
            "Tricep Pushdown": ["arms"],
            "Overhead Tricep Extension": ["arms"],
            "Close Grip Bench Press": ["chest", "arms"],
            "Diamond Push-ups": ["chest", "arms"],

            // Shoulders
            "Lateral Raise": ["shoulders"],
            "Face Pull": ["shoulders", "back"],
            "Rear Delt Fly": ["shoulders", "back"],

            // Legs Isolation
            "Leg Extension": ["legs"],
            "Leg Curl": ["legs"],

            // Core
            "Cable Crunch": ["core"],
            "Plank": ["core"]
        ]

        // Get body parts this exercise targets
        guard let targetedBodyParts = exerciseBodyParts[exerciseName] else {
            return nil // Unknown exercise, no substitution
        }

        // Check if any pain flags affect this exercise
        for painFlag in painFlags {
            let painBodyPart = painFlag.bodyPart.lowercased()

            if targetedBodyParts.contains(painBodyPart) {
                // Need substitution - find a completely different body part
                // Strategy: Map painful body part to safe alternative body parts
                let painFreeAlternatives = findPainFreeAlternatives(
                    painBodyPart: painBodyPart,
                    allExercises: exerciseBodyParts
                )

                if let substitute = painFreeAlternatives.first {
                    let severity = painFlag.severity
                    let reason = "Pain flag: \(severity) \(painBodyPart) pain"
                    return (substitute, reason)
                }

                // No good alternative found
                return nil
            }
        }

        return nil // No substitution needed
    }

    /// Find exercises that don't target the painful body part
    /// Prioritizes exercises that target opposite/unrelated muscle groups
    private func findPainFreeAlternatives(
        painBodyPart: String,
        allExercises: [String: [String]]
    ) -> [String] {
        // Define which body parts to prefer based on what hurts
        // Strategy: If upper body hurts → suggest lower body, and vice versa
        let preferredBodyParts: [String]

        switch painBodyPart {
        case "chest", "shoulders", "arms", "back":
            // Upper body pain → prefer leg exercises
            preferredBodyParts = ["legs", "core"]
        case "legs":
            // Leg pain → prefer upper body
            preferredBodyParts = ["back", "chest"]
        case "core":
            // Core pain → prefer limb exercises
            preferredBodyParts = ["legs", "arms"]
        default:
            preferredBodyParts = []
        }

        var candidates: [String] = []

        // First pass: Find exercises targeting preferred body parts
        for (exerciseName, bodyParts) in allExercises {
            // Skip if this exercise targets the painful body part
            if bodyParts.contains(painBodyPart) {
                continue
            }

            // Prioritize exercises targeting preferred body parts
            if bodyParts.contains(where: { preferredBodyParts.contains($0) }) {
                candidates.append(exerciseName)
            }
        }

        // If no preferred alternatives, accept any exercise that doesn't target pain
        if candidates.isEmpty {
            for (exerciseName, bodyParts) in allExercises where !bodyParts.contains(painBodyPart) {
                candidates.append(exerciseName)
            }
        }

        // Prioritize compound movements
        let compoundMovements = [
            "Barbell Squat", "Deadlift", "Romanian Deadlift",
            "Barbell Row", "Pull-ups", "Lat Pulldown",
            "Leg Press", "Bulgarian Split Squat"
        ]

        let compoundCandidates = candidates.filter { compoundMovements.contains($0) }

        return compoundCandidates.isEmpty ? candidates : compoundCandidates
    }

    // MARK: - Weekly Review

    func generateWeeklyReview(context: WeeklyReviewContext) async -> WeeklyReviewResponse {
        var highlights: [String] = []
        var areasToImprove: [String] = []

        // Check for PRs
        let prs = context.exerciseHighlights.filter { highlight in
            guard let previous = highlight.previousBestE1RM else { return false }
            return highlight.bestE1RM > previous
        }

        if !prs.isEmpty {
            let prNames = prs.prefix(3).map { $0.exerciseName }
            highlights.append("Hit PRs on \(prNames.joined(separator: ", "))")
        }

        // Consistency scoring
        let consistencyScore: Int
        let consistencyMessage: String

        switch context.workoutCount {
        case 0:
            consistencyScore = 1
            consistencyMessage = "No workouts recorded this period."
        case 1:
            consistencyScore = 3
            consistencyMessage = "You completed 1 workout."
        case 2:
            consistencyScore = 5
            consistencyMessage = "You completed 2 workouts."
        case 3:
            consistencyScore = 7
            consistencyMessage = "You completed 3 workouts. Good consistency!"
        case 4:
            consistencyScore = 8
            consistencyMessage = "You completed 4 workouts. Excellent consistency!"
        default:
            consistencyScore = 9
            consistencyMessage = "You completed \(context.workoutCount) workouts. Outstanding commitment!"
        }

        if context.workoutCount >= 4 {
            highlights.append("Maintained excellent training frequency")
        }

        // Volume analysis
        if context.totalVolume > 15000 {
            highlights.append("High training volume (\(Int(context.totalVolume / 1000))k kg)")
        } else if context.totalVolume > 8000 {
            highlights.append("Solid training volume this week")
        }

        // Areas to improve
        if context.workoutCount < 3 {
            areasToImprove.append("Try to fit in at least 3 sessions per week for optimal progress")
        }

        if prs.isEmpty && context.workoutCount >= 2 {
            areasToImprove.append("Focus on progressive overload - aim for small weight or rep increases")
        }

        if context.averageDuration < 40 && context.workoutCount > 0 {
            areasToImprove.append("Consider longer sessions to include more accessory work")
        }

        // Build summary
        var summary = consistencyMessage

        if !prs.isEmpty {
            summary += " You set \(prs.count) personal record(s)."
        }

        if context.totalVolume > 10000 {
            summary += " Your volume is on track."
        } else if context.workoutCount > 0 {
            summary += " There's room to increase volume if recovery allows."
        }

        // Recommendation
        let recommendation: String
        if context.workoutCount < 2 {
            recommendation = "Prioritize getting to the gym at least 3 times this week."
        } else if prs.isEmpty {
            recommendation = "Focus on adding 1 rep or 2.5kg to your main lifts this week."
        } else if context.totalVolume > 15000 {
            recommendation = "Monitor fatigue levels and consider a lighter week if needed."
        } else {
            recommendation = "Keep up the momentum! Stay consistent and trust the process."
        }

        return WeeklyReviewResponse(
            summary: summary,
            highlights: highlights.isEmpty ? ["Showed up and put in the work"] : highlights,
            areasToImprove: areasToImprove.isEmpty ? ["Keep pushing - you're on track"] : areasToImprove,
            recommendation: recommendation,
            consistencyScore: consistencyScore
        )
    }
}
