import SwiftUI
import SwiftData

struct CustomWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var recentSessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.dayNumber) private var existingTemplates: [WorkoutTemplate]
    
    let profile: UserProfile?
    let onStartWorkout: (CustomWorkoutResponse) -> Void
    
    @State private var prompt = ""
    @State private var timeAvailable = 45
    @State private var isGenerating = false
    @State private var generatedWorkout: CustomWorkoutResponse?
    @State private var errorMessage: String?
    @State private var showSaveConfirmation = false
    @State private var savedTemplateName: String?
    
    @FocusState private var isPromptFocused: Bool
    
    private let timeOptions = [30, 45, 60, 75, 90]
    private let examplePrompts = [
        "Upper body push focused",
        "Quick leg workout",
        "Back and biceps",
        "Full body compound lifts",
        "Chest and shoulders"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    if generatedWorkout == nil {
                        inputSection
                    }
                    
                    // Generated Workout Preview
                    if let workout = generatedWorkout {
                        workoutPreviewSection(workout)
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        errorSection(error)
                    }
                }
                .padding()
            }
            .navigationTitle(generatedWorkout == nil ? "Custom Workout" : "Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                if generatedWorkout != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Regenerate") {
                            generatedWorkout = nil
                            errorMessage = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: 20) {
            // AI Badge
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Powered by AI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.purple.opacity(0.1))
            .clipShape(Capsule())
            
            // Prompt Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe your workout")
                    .font(.headline)
                
                TextField("e.g., Upper body push focused", text: $prompt, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isPromptFocused)
                    .lineLimit(2...4)
            }
            
            // Example Prompts
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick picks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(examplePrompts, id: \.self) { example in
                        Button {
                            prompt = example
                        } label: {
                            Text(example)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(prompt == example ? Color.blue : Color(.systemGray5))
                                .foregroundStyle(prompt == example ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Divider()
            
            // Time Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Time available")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(timeOptions, id: \.self) { time in
                        Button {
                            timeAvailable = time
                        } label: {
                            Text("\(time) min")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(timeAvailable == time ? Color.blue : Color(.systemGray6))
                                .foregroundStyle(timeAvailable == time ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            
            // Provider Info
            if let provider = profile?.preferredLLMProvider, provider != .offline {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Using \(provider.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Configure an AI provider in Settings to use this feature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Generate Button
            Button {
                generateWorkout()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isGenerating ? "Creating workout..." : "Generate Workout")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canGenerate ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canGenerate || isGenerating)
        }
    }
    
    // MARK: - Workout Preview Section
    
    private func workoutPreviewSection(_ workout: CustomWorkoutResponse) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text(workout.workoutName)
                    .font(.title2.bold())
                
                HStack(spacing: 16) {
                    Label("\(workout.exercises.count) exercises", systemImage: "dumbbell")
                    Label("~\(workout.estimatedDuration) min", systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                // Focus Areas
                HStack(spacing: 8) {
                    ForEach(workout.focusAreas, id: \.self) { area in
                        Text(area)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Divider()
            
            // Exercise List
            VStack(alignment: .leading, spacing: 12) {
                Text("Exercises")
                    .font(.headline)
                
                ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                    CustomExerciseRow(exercise: exercise, index: index + 1)
                }
            }
            
            // Reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("Why this workout?")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                
                Text(workout.reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    onStartWorkout(workout)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    saveAsTemplate(workout)
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save as Template")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Save confirmation
            if let templateName = savedTemplateName {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Saved as '\(templateName)'")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Error Section
    
    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                errorMessage = nil
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helpers
    
    private var canGenerate: Bool {
        !prompt.isEmpty && profile?.preferredLLMProvider != .offline
    }
    
    private func saveAsTemplate(_ workout: CustomWorkoutResponse) {
        // Create a new template with the next day number
        let nextDayNumber = (existingTemplates.map { $0.dayNumber }.max() ?? 0) + 1
        
        let template = WorkoutTemplate(
            name: workout.workoutName,
            dayNumber: nextDayNumber,
            targetDuration: workout.estimatedDuration
        )
        
        // Create ExerciseTemplates for each exercise
        for (index, exercisePlan) in workout.exercises.enumerated() {
            // Find matching exercise from library
            var matchingExercise = exercises.first {
                $0.name.lowercased() == exercisePlan.exerciseName.lowercased()
            }
            
            // If exercise doesn't exist in library, create it from LLM metadata
            if matchingExercise == nil {
                matchingExercise = createExerciseFromPlan(exercisePlan)
            }
            
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
            
            // Create prescription from the workout plan
            let prescription = Prescription(
                progressionType: .straightSets,
                topSetRepsMin: minReps,
                topSetRepsMax: maxReps,
                topSetRPECap: exercisePlan.rpeCap,
                backoffSets: 0,
                backoffRepsMin: minReps,
                backoffRepsMax: maxReps,
                backoffLoadDropPercent: 0,
                workingSets: exercisePlan.sets
            )
            
            let exerciseTemplate = ExerciseTemplate(
                exercise: matchingExercise,
                orderIndex: index,
                isOptional: false,
                prescription: prescription
            )
            
            template.exercises.append(exerciseTemplate)
            modelContext.insert(exerciseTemplate)
        }
        
        // Insert the template
        modelContext.insert(template)
        
        // Save to persist
        try? modelContext.save()
        
        // Show confirmation
        withAnimation {
            savedTemplateName = workout.workoutName
        }
        
        // Hide confirmation after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                savedTemplateName = nil
            }
        }
    }
    
    /// Creates a new Exercise from LLM-provided metadata when exercise doesn't exist in library
    private func createExerciseFromPlan(_ plan: CustomExercisePlan) -> Exercise {
        // Parse movement pattern from LLM response or infer from name
        let movementPattern = parseMovementPattern(plan.movementPattern, exerciseName: plan.exerciseName)
        
        // Parse primary muscles from LLM response or infer from movement pattern
        let primaryMuscles = parseMuscles(plan.primaryMuscles, movementPattern: movementPattern)
        
        // Parse equipment from LLM response or use defaults
        let equipment = parseEquipment(plan.equipmentRequired, exerciseName: plan.exerciseName)
        
        // Determine if compound based on LLM response or movement pattern
        let isCompound = plan.isCompound ?? (movementPattern != .isolation)
        
        let exercise = Exercise(
            name: plan.exerciseName,
            movementPattern: movementPattern,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: [],
            equipmentRequired: equipment,
            isCompound: isCompound,
            defaultProgressionType: isCompound ? .topSetBackoff : .doubleProgression,
            instructions: plan.notes
        )
        
        modelContext.insert(exercise)
        return exercise
    }
    
    /// Parses movement pattern from LLM string or infers from exercise name
    private func parseMovementPattern(_ pattern: String?, exerciseName: String) -> MovementPattern {
        if let pattern = pattern?.lowercased() {
            switch pattern {
            case "squat": return .squat
            case "hinge": return .hinge
            case "lunge": return .lunge
            case "horizontalpush", "horizontal_push", "horizontal push": return .horizontalPush
            case "horizontalpull", "horizontal_pull", "horizontal pull": return .horizontalPull
            case "verticalpush", "vertical_push", "vertical push": return .verticalPush
            case "verticalpull", "vertical_pull", "vertical pull": return .verticalPull
            case "carry": return .carry
            case "isolation": return .isolation
            case "mobility": return .mobility
            case "cardio": return .cardio
            default: break
            }
        }
        
        // Infer from exercise name
        let name = exerciseName.lowercased()
        if name.contains("squat") { return .squat }
        if name.contains("deadlift") || name.contains("rdl") || name.contains("hip thrust") { return .hinge }
        if name.contains("lunge") || name.contains("split squat") || name.contains("step") { return .lunge }
        if name.contains("bench") || name.contains("push-up") || name.contains("pushup") || name.contains("chest press") { return .horizontalPush }
        if name.contains("row") || name.contains("pull") && !name.contains("pulldown") && !name.contains("pull-up") { return .horizontalPull }
        if name.contains("press") && (name.contains("overhead") || name.contains("shoulder") || name.contains("military")) { return .verticalPush }
        if name.contains("pulldown") || name.contains("pull-up") || name.contains("pullup") || name.contains("chin") || name.contains("lat") { return .verticalPull }
        if name.contains("carry") || name.contains("walk") { return .carry }
        if name.contains("curl") || name.contains("extension") || name.contains("raise") || name.contains("fly") || name.contains("kickback") { return .isolation }
        if name.contains("crunch") || name.contains("plank") || name.contains("ab") || name.contains("core") { return .isolation } // Core exercises are isolation
        
        return .isolation // Default fallback
    }
    
    /// Parses muscles from LLM strings or infers from movement pattern
    private func parseMuscles(_ muscles: [String]?, movementPattern: MovementPattern) -> [Muscle] {
        if let muscles = muscles, !muscles.isEmpty {
            return muscles.compactMap { muscleString -> Muscle? in
                let name = muscleString.lowercased()
                switch name {
                case "chest", "pecs", "pectorals": return .chest
                case "lats", "latissimus": return .lats
                case "upper back", "upperback": return .upperBack
                case "lower back", "lowerback": return .lowerBack
                case "quads", "quadriceps": return .quads
                case "hamstrings", "hams": return .hamstrings
                case "front delt", "front delts", "frontdelt", "front shoulders": return .frontDelt
                case "side delt", "side delts", "sidedelt", "lateral delt": return .sideDelt
                case "rear delt", "rear delts", "reardelt", "posterior delt": return .rearDelt
                case "shoulders", "delts", "deltoids": return .frontDelt // Default to front delt for generic shoulders
                case "biceps": return .biceps
                case "triceps": return .triceps
                case "glutes": return .glutes
                case "calves": return .calves
                case "abs", "core", "abdominals": return .core
                case "forearms": return .forearms
                case "traps", "trapezius": return .traps
                default: return nil
                }
            }
        }
        
        // Infer from movement pattern using its primaryMuscleGroups
        return movementPattern.primaryMuscleGroups
    }
    
    /// Parses equipment from LLM strings or infers from exercise name
    private func parseEquipment(_ equipment: [String]?, exerciseName: String) -> [Equipment] {
        if let equipment = equipment, !equipment.isEmpty {
            return equipment.compactMap { equipString -> Equipment? in
                let name = equipString.lowercased()
                switch name {
                case "barbell", "bar": return .barbell
                case "dumbbell", "dumbbells", "db": return .dumbbell
                case "cable", "cables": return .cable
                case "machine", "machines": return .machine
                case "bodyweight", "body weight", "bw": return .bodyweight
                case "bench": return .bench
                case "rack", "squat rack", "power rack": return .rack
                case "pullup bar", "pull-up bar", "chinup bar": return .pullUpBar
                case "band", "bands", "resistance band": return .bands
                default: return nil
                }
            }
        }
        
        // Infer from exercise name
        let name = exerciseName.lowercased()
        if name.contains("barbell") || name.contains("bb ") { return [.barbell] }
        if name.contains("dumbbell") || name.contains("db ") { return [.dumbbell] }
        if name.contains("cable") { return [.cable] }
        if name.contains("machine") { return [.machine] }
        if name.contains("bodyweight") || name.contains("push-up") || name.contains("pull-up") || name.contains("dip") { return [.bodyweight] }
        if name.contains("bench press") { return [.barbell, .bench] }
        if name.contains("squat") && !name.contains("goblet") { return [.barbell, .rack] }
        
        return [.dumbbell] // Default fallback
    }
    
    private func generateWorkout() {
        guard let profile = profile else { return }
        
        isGenerating = true
        errorMessage = nil
        isPromptFocused = false
        
        Task {
            do {
                let request = buildRequest()
                let workout = try await LLMService.shared.generateCustomWorkout(
                    request: request,
                    provider: profile.preferredLLMProvider
                )
                
                await MainActor.run {
                    generatedWorkout = workout
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
    private func buildRequest() -> CustomWorkoutRequest {
        // Build available exercises info
        let equipment = profile?.equipmentProfile
        let availableEquipment = equipment?.availableEquipment.map { $0.rawValue } ?? []
        
        let availableExercises = exercises
            .filter { exercise in
                // Filter by available equipment
                exercise.equipmentRequired.allSatisfy { required in
                    availableEquipment.contains(required.rawValue) || required == .bodyweight
                }
            }
            .map { exercise in
                AvailableExerciseInfo(
                    name: exercise.name,
                    movementPattern: exercise.movementPattern.rawValue,
                    primaryMuscles: exercise.primaryMuscles.map { $0.rawValue },
                    isCompound: exercise.isCompound,
                    equipmentRequired: exercise.equipmentRequired.map { $0.rawValue }
                )
            }
        
        // Build recent history (last known e1RM for each exercise)
        var recentHistory: [String: Double] = [:]
        for session in recentSessions.prefix(10) {
            for set in session.sets where set.isCompleted && set.setType != .warmup {
                guard let exerciseName = set.exercise?.name else { continue }
                if recentHistory[exerciseName] == nil || set.e1RM > recentHistory[exerciseName]! {
                    recentHistory[exerciseName] = set.e1RM
                }
            }
        }
        
        return CustomWorkoutRequest(
            userPrompt: prompt,
            availableExercises: availableExercises,
            equipmentAvailable: availableEquipment,
            userGoal: profile?.goal.rawValue ?? "Both",
            location: equipment?.location.rawValue ?? "Gym",
            timeAvailable: timeAvailable,
            recentExerciseHistory: recentHistory
        )
    }
}

// MARK: - Custom Exercise Row

struct CustomExerciseRow: View {
    let exercise: CustomExercisePlan
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.subheadline.bold())
                
                HStack(spacing: 12) {
                    Text("\(exercise.sets) × \(exercise.reps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("@RPE \(Int(exercise.rpeCap))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let weight = exercise.suggestedWeight, weight > 0 {
                        Text("~\(Int(weight))kg")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    CustomWorkoutSheet(
        profile: nil,
        onStartWorkout: { _ in }
    )
}
