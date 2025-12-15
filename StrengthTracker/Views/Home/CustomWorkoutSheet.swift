import SwiftUI
import SwiftData

struct CustomWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var recentSessions: [WorkoutSession]
    
    let profile: UserProfile?
    let onStartWorkout: (CustomWorkoutResponse) -> Void
    
    @State private var prompt = ""
    @State private var timeAvailable = 45
    @State private var isGenerating = false
    @State private var generatedWorkout: CustomWorkoutResponse?
    @State private var errorMessage: String?
    
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
