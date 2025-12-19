import SwiftUI
import SwiftData

struct AIPlanGeneratorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    @Query private var exercises: [Exercise]
    
    /// Callback when a plan is successfully created
    var onPlanCreated: (() -> Void)?
    
    // Wizard state
    @State private var currentStep = 0
    
    // Step 1: Goal
    @State private var goal: Goal = .both
    
    // Step 2: Duration
    @State private var durationWeeks = 8
    @State private var daysPerWeek = 4
    
    // Step 3: Split & Equipment
    @State private var split: Split = .upperLower
    @State private var includeDeloads = true
    
    // Step 4: Focus (optional)
    @State private var focusMuscles: Set<Muscle> = []
    
    // Generation state
    @State private var isGenerating = false
    @State private var generatedPlan: GeneratedPlanResponse?
    @State private var errorMessage: String?
    
    private var profile: UserProfile? { userProfiles.first }
    
    private let steps = ["Goal", "Schedule", "Structure", "Focus", "Generate"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                StepProgressBar(currentStep: currentStep, totalSteps: steps.count)
                    .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    PlanGoalStep(goal: $goal)
                        .tag(0)
                    
                    ScheduleStep(durationWeeks: $durationWeeks, daysPerWeek: $daysPerWeek)
                        .tag(1)
                    
                    StructureStep(split: $split, includeDeloads: $includeDeloads, daysPerWeek: daysPerWeek)
                        .tag(2)
                    
                    FocusStep(focusMuscles: $focusMuscles)
                        .tag(3)
                    
                    GenerateStep(
                        isGenerating: isGenerating,
                        generatedPlan: generatedPlan,
                        errorMessage: errorMessage,
                        onRetry: generatePlan
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 && currentStep < 4 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < 4 {
                        Button(currentStep == 3 ? "Generate Plan" : "Next") {
                            withAnimation {
                                if currentStep == 3 {
                                    currentStep = 4
                                    generatePlan()
                                } else {
                                    currentStep += 1
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else if generatedPlan != nil {
                        Button("Create Plan") {
                            savePlan()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Plan Generator")
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
    
    private func generatePlan() {
        guard let profile = profile else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let availableEquipment: [Equipment]
                if let equipment = profile.equipmentProfile?.availableEquipment {
                    availableEquipment = Array(equipment)
                } else {
                    availableEquipment = Equipment.allCases.map { $0 }
                }
                
                let request = GeneratePlanRequest(
                    goal: goal,
                    durationWeeks: durationWeeks,
                    daysPerWeek: daysPerWeek,
                    split: split,
                    equipment: availableEquipment,
                    includeDeloads: includeDeloads,
                    focusAreas: focusMuscles.isEmpty ? nil : Array(focusMuscles)
                )
                
                generatedPlan = try await LLMService.shared.generateWorkoutPlan(
                    request: request,
                    provider: profile.preferredLLMProvider
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isGenerating = false
        }
    }
    
    private func savePlan() {
        guard let response = generatedPlan else { return }
        
        // Create the plan
        let plan = WorkoutPlan(
            name: response.planName,
            planDescription: response.description,
            durationWeeks: durationWeeks,
            workoutsPerWeek: daysPerWeek,
            goal: goal
        )
        
        // Create weeks and templates from generated data
        for genWeek in response.weeks {
            let weekType: WeekType = {
                switch genWeek.weekType.lowercased() {
                case "deload": return .deload
                case "peak": return .peak
                case "test": return .test
                default: return .regular
                }
            }()
            
            let week = PlanWeek(
                weekNumber: genWeek.weekNumber,
                weekType: weekType,
                notes: genWeek.weekNotes
            )
            
            // Create templates for each workout
            var weekTemplates: [WorkoutTemplate] = []
            for genWorkout in genWeek.workouts {
                let template = WorkoutTemplate(
                    name: genWorkout.name,
                    dayNumber: genWorkout.dayNumber,
                    targetDuration: genWorkout.targetDuration
                )
                
                // Insert template first so relationships can be established
                modelContext.insert(template)

                // Create exercise templates
                for (index, genExercise) in genWorkout.exercises.enumerated() {
                    // Find matching exercise from library using fuzzy matching
                    let matchingExercise = ExerciseMatcher.findBestMatch(
                        name: genExercise.exerciseName,
                        in: exercises
                    )

                    if matchingExercise == nil {
                        print("⚠️ No matching exercise found for: \(genExercise.exerciseName)")
                    }

                    let exerciseTemplate = ExerciseTemplate(
                        exercise: matchingExercise,
                        orderIndex: index,
                        prescription: Prescription(
                            progressionType: goal == .strength ? .topSetBackoff : .doubleProgression,
                            topSetRepsMin: genExercise.repsMin,
                            topSetRepsMax: genExercise.repsMax,
                            topSetRPECap: genExercise.rpe ?? 8.0,
                            backoffSets: max(0, genExercise.sets - 1),
                            backoffRepsMin: genExercise.repsMin,
                            backoffRepsMax: genExercise.repsMax,
                            backoffLoadDropPercent: 0.10,
                            workingSets: genExercise.sets
                        )
                    )

                    // Set the inverse relationship and insert into context
                    exerciseTemplate.template = template
                    template.exercises.append(exerciseTemplate)
                    modelContext.insert(exerciseTemplate)
                }
                weekTemplates.append(template)
            }
            
            week.templates = weekTemplates
            week.plan = plan
            plan.weeks.append(week)
        }
        
        modelContext.insert(plan)
        try? modelContext.save()

        // Dismiss this sheet and notify parent
        dismiss()
        onPlanCreated?()
    }
}

// MARK: - Step Views

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .clipShape(Capsule())
            }
        }
    }
}

struct PlanGoalStep: View {
    @Binding var goal: Goal
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What's your main goal?")
                    .font(.title2.bold())
                Text("We'll optimize your plan accordingly")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(Goal.allCases) { g in
                    GoalOptionButton(
                        goal: g,
                        isSelected: goal == g,
                        onTap: { goal = g }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct GoalOptionButton: View {
    let goal: Goal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: goal.icon)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(goal.rawValue)
                        .font(.headline)
                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ScheduleStep: View {
    @Binding var durationWeeks: Int
    @Binding var daysPerWeek: Int
    
    let weekOptions = [4, 6, 8, 12]
    let dayOptions = [3, 4, 5, 6]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("How long is your program?")
                    .font(.title2.bold())
                Text("We'll structure progressions accordingly")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Duration")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ForEach(weekOptions, id: \.self) { weeks in
                        OptionChip(
                            title: "\(weeks) weeks",
                            isSelected: durationWeeks == weeks,
                            onTap: { durationWeeks = weeks }
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Training Days per Week")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ForEach(dayOptions, id: \.self) { days in
                        OptionChip(
                            title: "\(days) days",
                            isSelected: daysPerWeek == days,
                            onTap: { daysPerWeek = days }
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct OptionChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct StructureStep: View {
    @Binding var split: Split
    @Binding var includeDeloads: Bool
    let daysPerWeek: Int
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Training Structure")
                    .font(.title2.bold())
                Text("Choose your preferred workout split")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(Split.allCases.filter { $0 != .custom }) { s in
                    SplitOptionButton(
                        split: s,
                        isSelected: split == s,
                        isRecommended: isRecommendedSplit(s),
                        onTap: { split = s }
                    )
                }
            }
            .padding(.horizontal)
            
            Toggle("Include Deload Weeks", isOn: $includeDeloads)
                .padding(.horizontal)
            
            if includeDeloads {
                Text("Deload weeks will be automatically placed for optimal recovery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private func isRecommendedSplit(_ s: Split) -> Bool {
        switch daysPerWeek {
        case 3: return s == .fullBody
        case 4: return s == .upperLower
        case 5...6: return s == .ppl
        default: return false
        }
    }
}

struct SplitOptionButton: View {
    let split: Split
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(split.rawValue)
                            .font(.headline)
                        if isRecommended {
                            Text("Recommended")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(split.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FocusStep: View {
    @Binding var focusMuscles: Set<Muscle>
    
    let primaryMuscles: [Muscle] = [.chest, .lats, .frontDelt, .quads, .hamstrings, .glutes]
    let secondaryMuscles: [Muscle] = [.biceps, .triceps, .calves, .core, .forearms]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Any areas to focus on?")
                    .font(.title2.bold())
                Text("Optional: Select muscles for extra attention")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Primary Muscles")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(primaryMuscles) { muscle in
                            MuscleChip(
                                muscle: muscle,
                                isSelected: focusMuscles.contains(muscle),
                                onTap: {
                                    if focusMuscles.contains(muscle) {
                                        focusMuscles.remove(muscle)
                                    } else {
                                        focusMuscles.insert(muscle)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Secondary Muscles")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(secondaryMuscles) { muscle in
                            MuscleChip(
                                muscle: muscle,
                                isSelected: focusMuscles.contains(muscle),
                                onTap: {
                                    if focusMuscles.contains(muscle) {
                                        focusMuscles.remove(muscle)
                                    } else {
                                        focusMuscles.insert(muscle)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if !focusMuscles.isEmpty {
                Text("Selected: \(focusMuscles.map { $0.rawValue }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct MuscleChip: View {
    let muscle: Muscle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(muscle.rawValue)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct GenerateStep: View {
    let isGenerating: Bool
    let generatedPlan: GeneratedPlanResponse?
    let errorMessage: String?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            if isGenerating {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Generating your plan...")
                        .font(.headline)
                    Text("This may take a moment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    Text("Generation Failed")
                        .font(.headline)
                    
                    // Show a user-friendly error message
                    Group {
                        if error.contains("JSON decode failed") || error.contains("Parse error") {
                            Text("Parse error: \(error)")
                        } else if error.contains("API") || error.contains("status") {
                            Text("API error: \(error)")
                        } else {
                            Text(error)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
                    Button("Try Again", action: onRetry)
                        .buttonStyle(.borderedProminent)
                }
            } else if let plan = generatedPlan {
                GeneratedPlanPreview(plan: plan)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(.purple)
                    Text("Ready to Generate")
                        .font(.headline)
                    Text("Tap the button below to create your plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

struct GeneratedPlanPreview: View {
    let plan: GeneratedPlanResponse
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Plan Generated!")
                            .font(.headline)
                    }
                    
                    Text(plan.planName)
                        .font(.title2.bold())
                    
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Week summary
                Text("Week Structure")
                    .font(.headline)
                
                ForEach(plan.weeks.prefix(4), id: \.weekNumber) { week in
                    HStack {
                        Text("Week \(week.weekNumber)")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(week.weekType.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("\(week.workouts.count) workouts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                if plan.weeks.count > 4 {
                    Text("+ \(plan.weeks.count - 4) more weeks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Coaching notes
                if !plan.coachingNotes.isEmpty {
                    Text("Coach's Notes")
                        .font(.headline)
                    
                    Text(plan.coachingNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }
}

#Preview {
    AIPlanGeneratorSheet()
        .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
