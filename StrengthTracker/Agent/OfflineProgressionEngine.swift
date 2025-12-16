import Foundation

/// Rule-based progression engine for offline/fallback mode
actor OfflineProgressionEngine {

    func generatePlan(context: CoachContext) async -> TodayPlanResponse {
        var exercises: [PlannedExerciseResponse] = []
        var adjustments: [String] = []
        var reasoning: [String] = []

        let readiness = Readiness(
            energy: EnergyLevel(rawValue: context.readiness.energy) ?? .ok,
            soreness: SorenessLevel(rawValue: context.readiness.soreness) ?? .none,
            timeAvailable: context.timeAvailable
        )

        // Apply readiness adjustments
        if readiness.shouldReduceIntensity {
            adjustments.append("Reduced intensity due to \(context.readiness.energy) energy / \(context.readiness.soreness) soreness")
        }

        for templateExercise in context.currentTemplate.exercises {
            // Skip optional exercises if time constrained
            if templateExercise.isOptional && context.timeAvailable <= 45 {
                reasoning.append("Skipped optional \(templateExercise.name) due to time constraint")
                continue
            }

            // Find history for this exercise
            let history = context.recentHistory.first { $0.exerciseName == templateExercise.name }

            let plannedExercise = planExercise(
                name: templateExercise.name,
                prescription: templateExercise.prescription,
                history: history,
                readiness: readiness
            )

            exercises.append(plannedExercise)

            if let lastSession = history?.lastSessions.first {
                reasoning.append("\(templateExercise.name): Last \(lastSession.topSetWeight)kg x \(lastSession.topSetReps)")
            }
        }

        let estimatedDuration = calculateDuration(exercises: exercises)

        return TodayPlanResponse(
            exercises: exercises,
            substitutions: [], // Handled separately
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

        return PlannedExerciseResponse(
            exerciseName: name,
            warmupSets: warmupSets,
            topSet: PlannedSetResponse(
                weight: topSetWeight,
                reps: topSetReps,
                rpeCap: rpeCap,
                setCount: 1
            ),
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
