import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]

    let template: WorkoutTemplate
    let plan: TodayPlanResponse?

    @State private var currentExerciseIndex = 0
    @State private var workoutStartTime = Date()
    @State private var showRestTimer = false
    @State private var restTimeRemaining: Int = 180
    @State private var showSummary = false
    @State private var showPainFlagSheet = false
    @State private var session: WorkoutSession?

    @State private var exerciseSets: [UUID: [WorkoutSet]] = [:]

    private var profile: UserProfile? { userProfiles.first }
    private var unitSystem: UnitSystem { profile?.unitSystem ?? .metric }

    private var currentTemplateExercise: ExerciseTemplate? {
        guard currentExerciseIndex < template.sortedExercises.count else { return nil }
        return template.sortedExercises[currentExerciseIndex]
    }

    private var currentExercise: Exercise? {
        currentTemplateExercise?.exercise
    }

    private var totalExercises: Int {
        template.exercises.count
    }

    private var completedSetsCount: Int {
        exerciseSets.values.flatMap { $0 }.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                WorkoutProgressBar(
                    currentExercise: currentExerciseIndex + 1,
                    totalExercises: totalExercises,
                    elapsedTime: workoutStartTime
                )

                if let exercise = currentExercise,
                   let templateExercise = currentTemplateExercise {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Exercise header
                            ExerciseHeader(
                                exercise: exercise,
                                templateExercise: templateExercise,
                                planData: plan?.exercises.first { $0.exerciseName == exercise.name },
                                onPainFlagTapped: {
                                    showPainFlagSheet = true
                                }
                            )

                            // Sets list
                            SetsList(
                                exercise: exercise,
                                templateExercise: templateExercise,
                                sets: exerciseSets[exercise.id] ?? [],
                                plan: plan?.exercises.first { $0.exerciseName == exercise.name },
                                unitSystem: unitSystem,
                                showRPE: profile?.rpeFamiliarity ?? false,
                                onSetCompleted: { set in
                                    completeSet(set, for: exercise)
                                },
                                onAddSet: {
                                    addSet(for: exercise, templateExercise: templateExercise)
                                },
                                onRepeatLast: {
                                    repeatLastSet(for: exercise)
                                }
                            )

                            // Navigation buttons
                            ExerciseNavigation(
                                canGoBack: currentExerciseIndex > 0,
                                canGoForward: currentExerciseIndex < totalExercises - 1,
                                isLastExercise: currentExerciseIndex == totalExercises - 1,
                                onBack: { currentExerciseIndex -= 1 },
                                onNext: { currentExerciseIndex += 1 },
                                onFinish: { showSummary = true }
                            )
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No Exercise",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("No exercises found in this template")
                    )
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") {
                        showSummary = true
                    }
                }
            }
            .sheet(isPresented: $showRestTimer) {
                RestTimerSheet(
                    seconds: $restTimeRemaining,
                    defaultTime: profile?.defaultRestTime ?? 180
                )
                .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showSummary) {
                WorkoutSummarySheet(
                    template: template,
                    exerciseSets: exerciseSets,
                    startTime: workoutStartTime,
                    provider: profile?.preferredLLMProvider ?? .offline,
                    onSave: saveWorkout,
                    onDiscard: {
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showPainFlagSheet) {
                if let exercise = currentExercise {
                    PainFlagSheet(exercise: exercise)
                        .presentationDetents([.medium])
                }
            }
            .onAppear {
                initializeWorkout()
            }
        }
    }

    private func initializeWorkout() {
        // Initialize sets for each exercise
        for templateExercise in template.sortedExercises {
            guard let exercise = templateExercise.exercise else { continue }

            var sets: [WorkoutSet] = []

            // Check if we have a plan
            if let plannedExercise = plan?.exercises.first(where: { $0.exerciseName == exercise.name }) {
                // Create sets from plan
                var orderIndex = 0

                // Warmup sets
                for warmup in plannedExercise.warmupSets {
                    for _ in 0..<warmup.setCount {
                        let set = WorkoutSet(
                            exercise: exercise,
                            setType: .warmup,
                            weight: warmup.weight,
                            targetReps: warmup.reps,
                            targetRPE: warmup.rpeCap,
                            orderIndex: orderIndex
                        )
                        sets.append(set)
                        orderIndex += 1
                    }
                }

                // Top set
                if let topSet = plannedExercise.topSet {
                    let set = WorkoutSet(
                        exercise: exercise,
                        setType: .topSet,
                        weight: topSet.weight,
                        targetReps: topSet.reps,
                        targetRPE: topSet.rpeCap,
                        orderIndex: orderIndex
                    )
                    sets.append(set)
                    orderIndex += 1
                }

                // Backoff sets
                for backoff in plannedExercise.backoffSets {
                    for _ in 0..<backoff.setCount {
                        let set = WorkoutSet(
                            exercise: exercise,
                            setType: .backoff,
                            weight: backoff.weight,
                            targetReps: backoff.reps,
                            targetRPE: backoff.rpeCap,
                            orderIndex: orderIndex
                        )
                        sets.append(set)
                        orderIndex += 1
                    }
                }

                // Working sets
                for working in plannedExercise.workingSets {
                    for _ in 0..<working.setCount {
                        let set = WorkoutSet(
                            exercise: exercise,
                            setType: .working,
                            weight: working.weight,
                            targetReps: working.reps,
                            targetRPE: working.rpeCap,
                            orderIndex: orderIndex
                        )
                        sets.append(set)
                        orderIndex += 1
                    }
                }
            } else {
                // Create default sets from template prescription
                let prescription = templateExercise.prescription

                // Default warmup sets (if compound)
                if exercise.isCompound {
                    for i in 0..<3 {
                        let set = WorkoutSet(
                            exercise: exercise,
                            setType: .warmup,
                            weight: 20 + Double(i) * 20,
                            targetReps: 5,
                            orderIndex: i
                        )
                        sets.append(set)
                    }
                }

                var orderIndex = sets.count

                // Top set
                if prescription.progressionType == .topSetBackoff {
                    let set = WorkoutSet(
                        exercise: exercise,
                        setType: .topSet,
                        weight: 0,
                        targetReps: prescription.topSetRepsMin,
                        targetRPE: prescription.topSetRPECap,
                        orderIndex: orderIndex
                    )
                    sets.append(set)
                    orderIndex += 1

                    // Backoff sets
                    for _ in 0..<prescription.backoffSets {
                        let set = WorkoutSet(
                            exercise: exercise,
                            setType: .backoff,
                            weight: 0,
                            targetReps: prescription.backoffRepsMin,
                            targetRPE: prescription.topSetRPECap,
                            orderIndex: orderIndex
                        )
                        sets.append(set)
                        orderIndex += 1
                    }
                } else {
                    // Working sets
                    for i in 0..<prescription.workingSets {
                        let set = WorkoutSet(
                            exercise: exercise,
                            setType: .working,
                            weight: 0,
                            targetReps: prescription.topSetRepsMin,
                            targetRPE: prescription.topSetRPECap,
                            orderIndex: orderIndex + i
                        )
                        sets.append(set)
                    }
                }
            }

            exerciseSets[exercise.id] = sets
        }
    }

    private func completeSet(_ set: WorkoutSet, for exercise: Exercise) {
        set.isCompleted = true
        set.timestamp = Date()

        // Start rest timer
        restTimeRemaining = profile?.defaultRestTime ?? 180
        showRestTimer = true
    }

    private func addSet(for exercise: Exercise, templateExercise: ExerciseTemplate) {
        var sets = exerciseSets[exercise.id] ?? []
        let lastSet = sets.last

        let newSet = WorkoutSet(
            exercise: exercise,
            setType: lastSet?.setType ?? .working,
            weight: lastSet?.weight ?? 0,
            targetReps: lastSet?.targetReps ?? templateExercise.prescription.topSetRepsMin,
            targetRPE: lastSet?.targetRPE,
            orderIndex: sets.count
        )

        sets.append(newSet)
        exerciseSets[exercise.id] = sets
    }

    private func repeatLastSet(for exercise: Exercise) {
        guard var sets = exerciseSets[exercise.id],
              let lastCompleted = sets.last(where: { $0.isCompleted }) else {
            return
        }

        let newSet = lastCompleted.duplicate()
        newSet.orderIndex = sets.count
        sets.append(newSet)
        exerciseSets[exercise.id] = sets
    }

    private func saveWorkout() {
        let session = WorkoutSession(
            template: template,
            date: workoutStartTime,
            location: profile?.equipmentProfile?.location ?? .gym,
            plannedDuration: template.targetDuration,
            actualDuration: Int(Date().timeIntervalSince(workoutStartTime) / 60),
            isCompleted: true
        )

        // Add all sets
        for (_, sets) in exerciseSets {
            for set in sets where set.isCompleted {
                set.session = session
                session.sets.append(set)
                modelContext.insert(set)
            }
        }

        modelContext.insert(session)
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Subviews

struct WorkoutProgressBar: View {
    let currentExercise: Int
    let totalExercises: Int
    let elapsedTime: Date

    @State private var elapsed: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(currentExercise), total: Double(totalExercises))

            HStack {
                Text("Exercise \(currentExercise)/\(totalExercises)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatDuration(elapsed))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .onReceive(timer) { _ in
            elapsed = Date().timeIntervalSince(elapsedTime)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ExerciseHeader: View {
    let exercise: Exercise
    let templateExercise: ExerciseTemplate
    let planData: PlannedExerciseResponse?
    var onPainFlagTapped: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exercise.name)
                    .font(.title2.bold())
                
                Spacer()
                
                // Pain flag button
                Button {
                    onPainFlagTapped?()
                } label: {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
            }

            HStack {
                Label(exercise.movementPattern.rawValue, systemImage: "figure.strengthtraining.traditional")
                Spacer()
                Text(templateExercise.prescription.progressionType.rawValue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Show plan reasoning if available
            if let _ = planData {
                // Could show adjustments here
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SetsList: View {
    let exercise: Exercise
    let templateExercise: ExerciseTemplate
    let sets: [WorkoutSet]
    let plan: PlannedExerciseResponse?
    let unitSystem: UnitSystem
    let showRPE: Bool
    let onSetCompleted: (WorkoutSet) -> Void
    let onAddSet: () -> Void
    let onRepeatLast: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Group sets by type
            let warmups = sets.filter { $0.setType == .warmup }
            let topSets = sets.filter { $0.setType == .topSet }
            let backoffs = sets.filter { $0.setType == .backoff }
            let working = sets.filter { $0.setType == .working }

            if !warmups.isEmpty {
                SetGroup(title: "Warmup", sets: warmups, unitSystem: unitSystem, showRPE: showRPE, onComplete: onSetCompleted)
            }

            if !topSets.isEmpty {
                SetGroup(title: "Top Set", sets: topSets, unitSystem: unitSystem, showRPE: showRPE, onComplete: onSetCompleted)
            }

            if !backoffs.isEmpty {
                SetGroup(title: "Backoffs", sets: backoffs, unitSystem: unitSystem, showRPE: showRPE, onComplete: onSetCompleted)
            }

            if !working.isEmpty {
                SetGroup(title: "Working Sets", sets: working, unitSystem: unitSystem, showRPE: showRPE, onComplete: onSetCompleted)
            }

            // Quick actions
            HStack(spacing: 12) {
                Button(action: onAddSet) {
                    Label("Add Set", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if sets.contains(where: { $0.isCompleted }) {
                    Button(action: onRepeatLast) {
                        Label("Repeat Last", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

struct SetGroup: View {
    let title: String
    let sets: [WorkoutSet]
    let unitSystem: UnitSystem
    let showRPE: Bool
    let onComplete: (WorkoutSet) -> Void

    @State private var expandWarmups = false

    private var isWarmup: Bool {
        sets.first?.setType == .warmup
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                if isWarmup {
                    Button {
                        expandWarmups.toggle()
                    } label: {
                        Image(systemName: expandWarmups ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                }
            }

            if !isWarmup || expandWarmups {
                ForEach(sets) { set in
                    SetRow(
                        set: set,
                        unitSystem: unitSystem,
                        showRPE: showRPE,
                        onComplete: { onComplete(set) }
                    )
                }
            } else {
                // Collapsed warmup summary
                let completed = sets.filter { $0.isCompleted }.count
                Text("\(completed)/\(sets.count) warmup sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct SetRow: View {
    @Bindable var set: WorkoutSet
    let unitSystem: UnitSystem
    let showRPE: Bool
    let onComplete: () -> Void

    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 12) {
            // Set type indicator
            Text(set.setType.shortLabel)
                .font(.caption.bold())
                .foregroundStyle(colorForSetType(set.setType))
                .frame(width: 20)

            // Weight
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if isEditing || !set.isCompleted {
                    TextField("0", value: $set.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                } else {
                    Text(unitSystem.formatWeight(set.weight))
                        .font(.body.bold())
                }
            }

            // Reps
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if isEditing || !set.isCompleted {
                    HStack(spacing: 8) {
                        Button {
                            if set.reps > 0 { set.reps -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }

                        Text("\(set.reps)")
                            .font(.body.bold())
                            .frame(minWidth: 30)

                        Button {
                            set.reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Text("\(set.reps)")
                            .font(.body.bold())

                        if set.reps != set.targetReps {
                            Text("(\(set.targetReps))")
                                .font(.caption)
                                .foregroundStyle(set.reps >= set.targetReps ? .green : .orange)
                        }
                    }
                }
            }

            // RPE (optional)
            if showRPE {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RPE")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if isEditing || !set.isCompleted {
                        Menu {
                            ForEach([6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0], id: \.self) { rpe in
                                Button("\(rpe, specifier: "%.1f")") {
                                    set.rpe = rpe
                                }
                            }
                        } label: {
                            Text(set.rpe.map { String(format: "%.1f", $0) } ?? "-")
                                .font(.body)
                                .frame(minWidth: 40)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    } else {
                        Text(set.rpe.map { String(format: "%.1f", $0) } ?? "-")
                            .font(.body.bold())
                    }
                }
            }

            Spacer()

            // Complete button
            if !set.isCompleted {
                Button {
                    if set.reps == 0 {
                        set.reps = set.targetReps
                    }
                    onComplete()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            } else {
                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "checkmark.circle" : "pencil.circle")
                        .font(.title2)
                        .foregroundStyle(isEditing ? .green : .secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(set.isCompleted ? Color.green.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(set.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func colorForSetType(_ type: SetType) -> Color {
        switch type {
        case .warmup: return .gray
        case .topSet: return .orange
        case .backoff: return .blue
        case .working: return .green
        }
    }
}

struct ExerciseNavigation: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let isLastExercise: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onFinish: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Label("Previous", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canGoBack)

            if isLastExercise {
                Button(action: onFinish) {
                    Label("Finish", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: onNext) {
                    Label("Next", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canGoForward)
            }
        }
        .padding(.top)
    }
}

#Preview {
    WorkoutView(
        template: WorkoutTemplate(name: "Upper A", dayNumber: 1),
        plan: nil
    )
    .modelContainer(for: [UserProfile.self, Exercise.self], inMemory: true)
}
