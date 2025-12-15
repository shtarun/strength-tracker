import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var recentSessions: [WorkoutSession]

    @State private var showReadinessCheck = false
    @State private var showActiveWorkout = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var todayPlan: TodayPlanResponse?
    @State private var isGeneratingPlan = false

    private var profile: UserProfile? { userProfiles.first }
    private var nextTemplate: WorkoutTemplate? {
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

                    // Today's workout card
                    if let template = nextTemplate {
                        TodayWorkoutCard(
                            template: template,
                            isLoading: isGeneratingPlan,
                            onStart: {
                                selectedTemplate = template
                                showReadinessCheck = true
                            }
                        )
                    } else if templates.isEmpty {
                        // No templates yet
                        ContentUnavailableView(
                            "No Workouts",
                            systemImage: "dumbbell.fill",
                            description: Text("Go to Templates tab to create your first workout")
                        )
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
            .sheet(isPresented: $showReadinessCheck) {
                if let template = selectedTemplate {
                    ReadinessCheckSheet(
                        template: template,
                        onStart: { readiness in
                            startWorkout(template: template, readiness: readiness)
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showActiveWorkout) {
                if let template = selectedTemplate {
                    WorkoutView(
                        template: template,
                        plan: todayPlan
                    )
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
        showReadinessCheck = false

        // Generate plan if LLM is configured
        if let profile = profile, profile.preferredLLMProvider != .offline {
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
                    showActiveWorkout = true
                }
            }
        } else {
            // Show workout after a small delay to allow sheet dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🏋️ Showing workout view (offline path)")
                showActiveWorkout = true
            }
        }
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
            painFlags: [] // TODO: Fetch active pain flags
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

struct TodayWorkoutCard: View {
    let template: WorkoutTemplate
    let isLoading: Bool
    let onStart: () -> Void
    
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

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, WorkoutTemplate.self, WorkoutSession.self], inMemory: true)
}
