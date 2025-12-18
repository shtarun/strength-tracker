import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var recentSessions: [WorkoutSession]
    @Query private var exercises: [Exercise]
    @Query private var painFlags: [PainFlag]
    @Query(sort: \PausedWorkout.pausedAt, order: .reverse) private var pausedWorkouts: [PausedWorkout]
    @Query(sort: \WorkoutPlan.updatedAt, order: .reverse) private var plans: [WorkoutPlan]

    @State private var showReadinessCheck = false
    @State private var showActiveWorkout = false
    @State private var showWorkoutPicker = false
    @State private var showCustomWorkout = false
    @State private var templateForReadiness: WorkoutTemplate?
    @State private var templateForWorkout: WorkoutTemplate?
    @State private var pausedWorkoutToResume: PausedWorkout?
    @State private var todayPlan: TodayPlanResponse?
    @State private var isGeneratingPlan = false
    @State private var manuallySelectedTemplate: WorkoutTemplate?
    @State private var customWorkoutResponse: CustomWorkoutResponse?
    @State private var showPlanDetail = false

    private var profile: UserProfile? { userProfiles.first }
    private var activePlan: WorkoutPlan? { plans.first { $0.isActive } }
    private var validPausedWorkout: PausedWorkout? {
        pausedWorkouts.first { $0.isValid && $0.template != nil }
    }
    
    /// Templates available for the current context (from plan if active, otherwise all templates)
    private var availableTemplates: [WorkoutTemplate] {
        if let plan = activePlan, let currentWeek = plan.currentPlanWeek {
            // Use templates from the active plan's current week
            return currentWeek.sortedTemplates
        }
        // Fall back to all templates if no active plan
        return templates
    }
    
    private var nextTemplate: WorkoutTemplate? {
        // If user manually selected a template, use that
        if let manual = manuallySelectedTemplate {
            return manual
        }
        
        // If there's an active plan, use the plan's next workout logic
        if let plan = activePlan, let currentWeek = plan.currentPlanWeek {
            let planTemplates = currentWeek.sortedTemplates
            guard !planTemplates.isEmpty else { return nil }
            
            // Find the most recent session that used a template from this plan
            if let lastSession = recentSessions.first,
               let lastTemplate = lastSession.template,
               let lastIndex = planTemplates.firstIndex(where: { $0.id == lastTemplate.id }) {
                // Return next template in sequence
                let nextIndex = (lastIndex + 1) % planTemplates.count
                return planTemplates[nextIndex]
            }
            
            // Return first template if no recent sessions match
            return planTemplates.first
        }
        
        // Fall back to standard template rotation (no active plan)
        guard let lastSession = recentSessions.first,
              let lastTemplate = lastSession.template,
              let index = templates.firstIndex(where: { $0.id == lastTemplate.id }) else {
            return templates.first
        }
        let nextIndex = (index + 1) % templates.count
        return templates[nextIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    if let profile = profile {
                        GreetingCard(name: profile.name)
                    }

                    // Debug: Log paused workouts state
                    let _ = {
                        print("🏠 HomeView: Total paused workouts: \(pausedWorkouts.count)")
                        for pw in pausedWorkouts {
                            print("🏠 - Paused workout: template=\(pw.template?.name ?? "nil"), isValid=\(pw.isValid), pausedAt=\(pw.pausedAt)")
                        }
                        print("🏠 validPausedWorkout: \(validPausedWorkout?.template?.name ?? "none")")
                    }()
                    
                    // Active plan card
                    if let plan = activePlan {
                        ActivePlanHomeCard(plan: plan)
                            .onTapGesture {
                                showPlanDetail = true
                            }
                    }

                    // Resume paused workout banner
                    if let paused = validPausedWorkout, let template = paused.template {
                        ResumeWorkoutCard(
                            pausedWorkout: paused,
                            template: template,
                            onResume: {
                                pausedWorkoutToResume = paused
                                todayPlan = paused.plan
                                templateForWorkout = template
                            },
                            onDiscard: {
                                modelContext.delete(paused)
                                try? modelContext.save()
                            }
                        )
                    }

                    // Today's workout card (only show if no paused workout)
                    if validPausedWorkout == nil, let template = nextTemplate {
                        TodayWorkoutCard(
                            template: template,
                            allTemplates: availableTemplates,
                            isLoading: isGeneratingPlan,
                            onStart: {
                                templateForReadiness = template
                            },
                            onSwap: {
                                showWorkoutPicker = true
                            }
                        )
                    } else if validPausedWorkout == nil && availableTemplates.isEmpty {
                        // No templates yet
                        ContentUnavailableView(
                            "No Workouts",
                            systemImage: "dumbbell.fill",
                            description: Text(activePlan != nil ? 
                                "Your current plan week has no workouts configured" :
                                "Go to Templates tab to create your first workout")
                        )
                    }
                    
                    // Custom workout button (AI-powered)
                    if profile?.preferredLLMProvider != .offline {
                        CustomWorkoutButton {
                            showCustomWorkout = true
                        }
                    }

                    // Quick stats
                    StatsCard(sessions: recentSessions)

                    // Recent workouts
                    if !recentSessions.isEmpty {
                        RecentWorkoutsSection(sessions: Array(recentSessions.prefix(3)))
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .sheet(item: $templateForReadiness) { template in
                ReadinessCheckSheet(
                    template: template,
                    onStart: { readiness in
                        startWorkout(template: template, readiness: readiness)
                    }
                )
            }
            .fullScreenCover(item: $templateForWorkout) { template in
                WorkoutView(
                    template: template,
                    plan: todayPlan,
                    resumingFrom: pausedWorkoutToResume
                )
                .onDisappear {
                    pausedWorkoutToResume = nil
                }
            }
            .sheet(isPresented: $showWorkoutPicker) {
                WorkoutPickerSheet(
                    templates: availableTemplates,
                    currentTemplate: nextTemplate,
                    onSelect: { template in
                        manuallySelectedTemplate = template
                        showWorkoutPicker = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showCustomWorkout) {
                CustomWorkoutSheet(
                    profile: profile,
                    onStartWorkout: { response in
                        customWorkoutResponse = response
                        startCustomWorkout(response: response)
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showPlanDetail) {
                if let plan = activePlan {
                    PlanDetailView(plan: plan)
                }
            }
        }
    }

    private func startWorkout(template: WorkoutTemplate, readiness: Readiness) {
        print("🏋️ Starting workout: \(template.name)")
        print("🏋️ Template has \(template.exercises.count) exercises")
        print("🏋️ Sorted exercises: \(template.sortedExercises.map { $0.exercise?.name ?? "nil" })")
        
        // Create workout session
        let session = WorkoutSession(
            template: template,
            location: profile?.equipmentProfile?.location ?? .gym,
            readiness: readiness,
            plannedDuration: readiness.timeAvailable
        )
        modelContext.insert(session)

        // Dismiss the readiness sheet first
        templateForReadiness = nil

        // Generate plan if LLM is configured AND readiness is not default
        // Only tweak the workout if user selected non-default values
        if let profile = profile, profile.preferredLLMProvider != .offline, !readiness.isDefault {
            Task {
                isGeneratingPlan = true
                do {
                    let context = buildCoachContext(template: template, readiness: readiness)
                    todayPlan = try await LLMService.shared.generatePlan(
                        context: context,
                        provider: profile.preferredLLMProvider
                    )
                } catch {
                    print("Failed to generate plan: \(error)")
                    todayPlan = nil
                }
                isGeneratingPlan = false

                // Wait for sheet dismissal before showing workout
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                await MainActor.run {
                    print("🏋️ Showing workout view (LLM path)")
                    templateForWorkout = template
                }
            }
        } else {
            // Show workout after a small delay to allow sheet dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🏋️ Showing workout view (offline path)")
                templateForWorkout = template
            }
        }
    }
    
    private func startCustomWorkout(response: CustomWorkoutResponse) {
        print("🏋️ Starting custom workout: \(response.workoutName)")
        print("🏋️ Custom workout has \(response.exercises.count) exercises")
        
        // Create an ad-hoc template from the custom workout response
        let customTemplate = WorkoutTemplate(
            name: response.workoutName,
            dayNumber: 0, // 0 indicates ad-hoc/custom workout
            targetDuration: response.estimatedDuration
        )
        
        // Create ExerciseTemplates for each exercise in the custom workout
        for (index, exercisePlan) in response.exercises.enumerated() {
            // Find matching exercise from library using fuzzy matching
            let matchingExercise = ExerciseMatcher.findBestMatch(
                name: exercisePlan.exerciseName,
                in: exercises
            )

            // Parse reps range (e.g., "8-10" or "5")
            let repsComponents = exercisePlan.reps.split(separator: "-")
            let minReps: Int
            let maxReps: Int

            if repsComponents.count == 2 {
                minReps = Int(repsComponents[0]) ?? 8
                maxReps = Int(repsComponents[1]) ?? 10
            } else {
                minReps = Int(exercisePlan.reps) ?? 8
                maxReps = minReps
            }

            // Create prescription from the custom workout plan
            let prescription = Prescription(
                progressionType: .straightSets, // Custom workouts use straight sets
                topSetRepsMin: minReps,
                topSetRepsMax: maxReps,
                topSetRPECap: exercisePlan.rpeCap,
                backoffSets: 0, // No backoffs for custom/straight sets
                backoffRepsMin: minReps,
                backoffRepsMax: maxReps,
                backoffLoadDropPercent: 0,
                workingSets: exercisePlan.sets // All sets are working sets
            )

            let exerciseTemplate = ExerciseTemplate(
                exercise: matchingExercise,
                orderIndex: index,
                isOptional: false,
                prescription: prescription
            )

            // Store exercise name if we couldn't find a match (for display purposes)
            if matchingExercise == nil {
                print("⚠️ Exercise not found in library: \(exercisePlan.exerciseName)")
            }

            customTemplate.exercises.append(exerciseTemplate)
            modelContext.insert(exerciseTemplate)
        }
        
        // Insert the custom template
        modelContext.insert(customTemplate)
        
        // Convert custom workout to plan format for WorkoutView
        todayPlan = convertCustomWorkoutToPlan(response: response)
        
        // Show workout after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🏋️ Showing workout view for custom workout with \(customTemplate.exercises.count) exercises")
            templateForWorkout = customTemplate
        }
    }
    
    /// Converts CustomWorkoutResponse to TodayPlanResponse format for WorkoutView compatibility
    private func convertCustomWorkoutToPlan(response: CustomWorkoutResponse) -> TodayPlanResponse {
        let exercisePlans = response.exercises.map { exercise -> PlannedExerciseResponse in
            // Parse reps for working sets
            let repsComponents = exercise.reps.split(separator: "-")
            let targetReps: Int
            if repsComponents.count == 2 {
                // Use middle of range
                let min = Int(repsComponents[0]) ?? 8
                let max = Int(repsComponents[1]) ?? 10
                targetReps = (min + max) / 2
            } else {
                targetReps = Int(exercise.reps) ?? 8
            }
            
            // Create warmup sets (lighter weights building up)
            var warmupSets: [PlannedSetResponse] = []
            if let suggestedWeight = exercise.suggestedWeight, suggestedWeight > 20 {
                // Add 2-3 warmup sets at progressively higher weights
                warmupSets = [
                    PlannedSetResponse(weight: suggestedWeight * 0.5, reps: 10, rpeCap: 5.0, setCount: 1),
                    PlannedSetResponse(weight: suggestedWeight * 0.7, reps: 6, rpeCap: 6.0, setCount: 1)
                ]
            }
            
            // Working sets (all sets at same weight for custom workouts)
            let workingSets = [
                PlannedSetResponse(
                    weight: exercise.suggestedWeight ?? 0,
                    reps: targetReps,
                    rpeCap: exercise.rpeCap,
                    setCount: exercise.sets
                )
            ]
            
            return PlannedExerciseResponse(
                exerciseName: exercise.exerciseName,
                warmupSets: warmupSets,
                topSet: nil, // Custom workouts use straight sets, not top set + backoffs
                backoffSets: [],
                workingSets: workingSets
            )
        }
        
        return TodayPlanResponse(
            exercises: exercisePlans,
            substitutions: [],
            adjustments: [],
            reasoning: [response.reasoning],
            estimatedDuration: response.estimatedDuration
        )
    }

    private func buildCoachContext(template: WorkoutTemplate, readiness: Readiness) -> CoachContext {
        let exerciseHistory = template.sortedExercises.compactMap { templateEx -> ExerciseHistoryContext? in
            guard let exercise = templateEx.exercise else { return nil }

            let history = getRecentHistory(for: exercise)
            return ExerciseHistoryContext(
                exerciseName: exercise.name,
                lastSessions: history
            )
        }

        let equipment = profile?.equipmentProfile
        let equipmentList = equipment?.availableEquipment.map { $0.rawValue } ?? []

        // Fetch active (recent and unresolved) pain flags
        let activePainFlags = painFlags
            .filter { $0.isRecent }
            .map { painFlag -> PainFlagContext in
                PainFlagContext(
                    exerciseName: painFlag.exercise?.name,
                    bodyPart: painFlag.bodyPart.rawValue,
                    severity: painFlag.severity.rawValue
                )
            }

        return CoachContext(
            userGoal: profile?.goal.rawValue ?? "Both",
            currentTemplate: TemplateContext(
                name: template.name,
                exercises: template.sortedExercises.compactMap { templateEx in
                    guard let exercise = templateEx.exercise else { return nil }
                    return TemplateExerciseContext(
                        name: exercise.name,
                        prescription: PrescriptionContext(
                            progressionType: templateEx.prescription.progressionType.rawValue,
                            topSetRepsRange: templateEx.prescription.topSetRepsRange,
                            topSetRPECap: templateEx.prescription.topSetRPECap,
                            backoffSets: templateEx.prescription.backoffSets,
                            backoffRepsRange: templateEx.prescription.backoffRepsRange,
                            backoffLoadDropPercent: templateEx.prescription.backoffLoadDropPercent
                        ),
                        isOptional: templateEx.isOptional
                    )
                }
            ),
            location: equipment?.location.rawValue ?? "Gym",
            readiness: ReadinessContext(
                energy: readiness.energy.rawValue,
                soreness: readiness.soreness.rawValue
            ),
            timeAvailable: readiness.timeAvailable,
            recentHistory: exerciseHistory,
            equipmentAvailable: equipmentList,
            painFlags: activePainFlags
        )
    }

    private func getRecentHistory(for exercise: Exercise) -> [SessionHistoryContext] {
        let relevantSessions = recentSessions
            .filter { session in
                session.sets.contains { $0.exercise?.id == exercise.id }
            }
            .prefix(5)

        return relevantSessions.compactMap { session -> SessionHistoryContext? in
            let sets = session.sets.filter { $0.exercise?.id == exercise.id && $0.isCompleted }
            guard let topSet = sets.filter({ $0.setType == .topSet }).first ?? sets.first else {
                return nil
            }

            let formatter = ISO8601DateFormatter()

            return SessionHistoryContext(
                date: formatter.string(from: session.date),
                topSetWeight: topSet.weight,
                topSetReps: topSet.reps,
                topSetRPE: topSet.rpe,
                totalSets: sets.count,
                e1RM: topSet.e1RM
            )
        }
    }
}

// MARK: - Subviews

struct GreetingCard: View {
    let name: String

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.title.bold())
            }
            Spacer()
        }
    }
}

// MARK: - Active Plan Home Card

struct ActivePlanHomeCard: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Plan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(plan.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            
            // Current week info
            if let week = plan.currentPlanWeek {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: week.weekType.icon)
                            .foregroundStyle(week.weekType.color)
                        Text("Week \(plan.currentWeek)/\(plan.durationWeeks)")
                    }
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(week.weekType.rawValue)
                        .foregroundStyle(week.weekType.color)
                    
                    Spacer()
                    
                    Text("\(plan.completedWorkoutsThisWeek)/\(plan.workoutsPerWeek) workouts")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
            
            // Progress bar
            ProgressView(value: plan.progressPercentage)
                .tint(.blue)
            
            // Deload week notice
            if plan.currentPlanWeek?.weekType == .deload {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Deload week: Reduce intensity to 60% and volume by half")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct ResumeWorkoutCard: View {
    let pausedWorkout: PausedWorkout
    let template: WorkoutTemplate
    let onResume: () -> Void
    let onDiscard: () -> Void

    @State private var showDiscardConfirmation = false

    private var pausedTimeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: pausedWorkout.pausedAt, relativeTo: Date())
    }

    private var elapsedTime: String {
        let minutes = Int(pausedWorkout.elapsedDuration / 60)
        return "\(minutes) min"
    }

    private var completedSetsCount: Int {
        pausedWorkout.exerciseSets.values.flatMap { $0 }.filter { $0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pause.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Paused Workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(template.name)
                        .font(.headline)
                }

                Spacer()

                Button {
                    showDiscardConfirmation = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                Label(pausedTimeAgo, systemImage: "clock")
                Label(elapsedTime + " elapsed", systemImage: "timer")
                Label("\(completedSetsCount) sets done", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button(action: onResume) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Resume Workout")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: .orange.opacity(0.2), radius: 8, y: 4)
        .confirmationDialog("Discard Workout?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard Progress", role: .destructive, action: onDiscard)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be lost. This cannot be undone.")
        }
    }
}

struct TodayWorkoutCard: View {
    let template: WorkoutTemplate
    let allTemplates: [WorkoutTemplate]
    let isLoading: Bool
    let onStart: () -> Void
    let onSwap: () -> Void
    
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(template.name)
                        .font(.title2.bold())
                }
                Spacer()

                // Swap button (only if more than one template)
                if allTemplates.count > 1 {
                    Button(action: onSwap) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }

                Text("\(template.targetDuration) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }

            // Exercise list - expandable
            VStack(alignment: .leading, spacing: 8) {
                let exercisesToShow = isExpanded ? template.sortedExercises : Array(template.sortedExercises.prefix(4))
                
                ForEach(exercisesToShow) { templateEx in
                    if let exercise = templateEx.exercise {
                        ExercisePreviewRow(
                            exercise: exercise,
                            templateExercise: templateEx,
                            isExpanded: isExpanded
                        )
                    }
                }

                // Expand/Collapse button
                if template.exercises.count > 4 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text(isExpanded ? "Show less" : "Show all \(template.exercises.count) exercises")
                                .font(.subheadline)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
            }

            Button(action: onStart) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(isLoading ? "Generating Plan..." : "Start Workout")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

struct CustomWorkoutButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create Custom Workout")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Use AI to build a workout from scratch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct ExercisePreviewRow: View {
    let exercise: Exercise
    let templateExercise: ExerciseTemplate
    let isExpanded: Bool
    
    private var prescription: Prescription {
        templateExercise.prescription
    }
    
    private var prescriptionSummary: String {
        if prescription.progressionType == .topSetBackoff {
            let topSet = "1×\(prescription.topSetRepsRange) @RPE\(Int(prescription.topSetRPECap))"
            let backoffs = prescription.backoffSets > 0 ? " + \(prescription.backoffSets)×\(prescription.backoffRepsRange)" : ""
            return topSet + backoffs
        } else {
            return "\(prescription.workingSets)×\(prescription.topSetRepsRange) @RPE\(Int(prescription.topSetRPECap))"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(templateExercise.isOptional ? Color.gray : Color.blue)
                    .frame(width: 6, height: 6)
                
                Text(exercise.name)
                    .font(.subheadline)
                    .foregroundStyle(templateExercise.isOptional ? .secondary : .primary)
                
                if templateExercise.isOptional {
                    Text("optional")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // Show prescription details when expanded
            if isExpanded {
                HStack(spacing: 12) {
                    Label(prescriptionSummary, systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if exercise.isCompound {
                        Label("Compound", systemImage: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.leading, 14)
                .padding(.top, 2)
            }
        }
        .padding(.vertical, isExpanded ? 4 : 0)
    }
}

struct StatsCard: View {
    let sessions: [WorkoutSession]

    private var thisWeekSessions: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessions.filter { $0.date >= startOfWeek && $0.isCompleted }.count
    }

    private var currentStreak: Int {
        var streak = 0
        var checkDate = Date()
        let calendar = Calendar.current

        for _ in 0..<30 {
            let dayStart = calendar.startOfDay(for: checkDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let hasWorkout = sessions.contains { session in
                session.date >= dayStart && session.date < dayEnd && session.isCompleted
            }

            if hasWorkout {
                streak += 1
            } else if streak > 0 {
                break
            }

            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        return streak
    }

    var body: some View {
        HStack(spacing: 16) {
            StatItem(
                title: "This Week",
                value: "\(thisWeekSessions)",
                icon: "calendar",
                color: .blue
            )

            StatItem(
                title: "Streak",
                value: "\(currentStreak) days",
                icon: "flame.fill",
                color: .orange
            )

            StatItem(
                title: "Total",
                value: "\(sessions.filter { $0.isCompleted }.count)",
                icon: "figure.strengthtraining.traditional",
                color: .green
            )
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RecentWorkoutsSection: View {
    let sessions: [WorkoutSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)

            ForEach(sessions) { session in
                RecentWorkoutRow(session: session)
            }
        }
    }
}

struct RecentWorkoutRow: View {
    let session: WorkoutSession

    private var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.date, relativeTo: Date())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.template?.name ?? "Workout")
                    .font(.subheadline.bold())

                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if session.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("Incomplete")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Workout Picker Sheet

struct WorkoutPickerSheet: View {
    let templates: [WorkoutTemplate]
    let currentTemplate: WorkoutTemplate?
    let onSelect: (WorkoutTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(templates) { template in
                        WorkoutPickerRow(
                            template: template,
                            isSelected: template.id == currentTemplate?.id,
                            onSelect: {
                                onSelect(template)
                            }
                        )
                    }
                } header: {
                    Text("Choose a workout")
                } footer: {
                    Text("Tap to select a different workout for today")
                        .font(.caption)
                }
            }
            .navigationTitle("Swap Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WorkoutPickerRow: View {
    let template: WorkoutTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if isSelected {
                            Text("Current")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(template.exercises.count) exercises", systemImage: "dumbbell")
                        Label("\(template.targetDuration) min", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    // Show first few exercises
                    if !template.sortedExercises.isEmpty {
                        let exerciseNames = template.sortedExercises.prefix(3)
                            .compactMap { $0.exercise?.name }
                            .joined(separator: ", ")
                        let remaining = template.exercises.count - 3
                        let suffix = remaining > 0 ? " +\(remaining) more" : ""
                        
                        Text(exerciseNames + suffix)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, WorkoutTemplate.self, WorkoutSession.self], inMemory: true)
}
