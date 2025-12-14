import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var name = ""
    @State private var goal: Goal = .both
    @State private var daysPerWeek = 4
    @State private var split: Split = .upperLower
    @State private var location: Location = .gym
    @State private var rpeFamiliarity = false
    @State private var unitSystem: UnitSystem = .metric

    // Equipment
    @State private var hasAdjustableDumbbells = true
    @State private var hasBarbell = true
    @State private var hasRack = true
    @State private var hasCables = true
    @State private var hasPullUpBar = true
    @State private var hasBands = false
    @State private var hasBench = true
    @State private var hasMachines = true

    // LLM
    @State private var llmProvider: LLMProviderType = .offline
    @State private var claudeAPIKey = ""
    @State private var openAIAPIKey = ""

    private let totalSteps = 6

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .padding(.horizontal)
                    .padding(.top)

                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep(name: $name)
                        .tag(0)

                    GoalStep(goal: $goal, unitSystem: $unitSystem)
                        .tag(1)

                    SplitStep(daysPerWeek: $daysPerWeek, split: $split)
                        .tag(2)

                    LocationStep(location: $location)
                        .tag(3)

                    EquipmentStep(
                        location: location,
                        hasAdjustableDumbbells: $hasAdjustableDumbbells,
                        hasBarbell: $hasBarbell,
                        hasRack: $hasRack,
                        hasCables: $hasCables,
                        hasPullUpBar: $hasPullUpBar,
                        hasBands: $hasBands,
                        hasBench: $hasBench,
                        hasMachines: $hasMachines
                    )
                    .tag(4)

                    CoachStep(
                        rpeFamiliarity: $rpeFamiliarity,
                        llmProvider: $llmProvider,
                        claudeAPIKey: $claudeAPIKey,
                        openAIAPIKey: $openAIAPIKey
                    )
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if currentStep < totalSteps - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                    } else {
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    private func completeOnboarding() {
        // Create user profile
        let profile = UserProfile(
            name: name,
            goal: goal,
            daysPerWeek: daysPerWeek,
            preferredSplit: split,
            rpeFamiliarity: rpeFamiliarity,
            unitSystem: unitSystem,
            preferredLLMProvider: llmProvider,
            claudeAPIKey: claudeAPIKey.isEmpty ? nil : claudeAPIKey,
            openAIAPIKey: openAIAPIKey.isEmpty ? nil : openAIAPIKey
        )

        // Create equipment profile
        let equipment = EquipmentProfile(
            location: location,
            hasAdjustableDumbbells: hasAdjustableDumbbells,
            hasBarbell: hasBarbell,
            hasRack: hasRack,
            hasCables: hasCables,
            hasPullUpBar: hasPullUpBar,
            hasBands: hasBands,
            hasBench: hasBench,
            hasMachines: hasMachines
        )

        profile.equipmentProfile = equipment
        modelContext.insert(profile)

        // Seed exercises synchronously first
        ExerciseLibrary.shared.seedExercises(in: modelContext)

        // Generate default templates after exercises are seeded
        TemplateGenerator.generateDefaultTemplates(
            for: profile,
            equipment: equipment,
            in: modelContext
        )

        // Configure LLM service
        LLMService.shared.configure(
            claudeAPIKey: claudeAPIKey.isEmpty ? nil : claudeAPIKey,
            openAIAPIKey: openAIAPIKey.isEmpty ? nil : openAIAPIKey
        )

        try? modelContext.save()
    }
}

// MARK: - Step Views

struct WelcomeStep: View {
    @Binding var name: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to\nStrength Tracker")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Your AI-powered strength coach")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("What's your name?")
                    .font(.headline)

                TextField("Enter your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct GoalStep: View {
    @Binding var goal: Goal
    @Binding var unitSystem: UnitSystem

    var body: some View {
        VStack(spacing: 24) {
            Text("What's your goal?")
                .font(.title.bold())
                .padding(.top, 32)

            VStack(spacing: 12) {
                ForEach(Goal.allCases) { g in
                    GoalCard(goal: g, isSelected: goal == g) {
                        goal = g
                    }
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 12) {
                Text("Preferred units")
                    .font(.headline)

                Picker("Units", selection: $unitSystem) {
                    ForEach(UnitSystem.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct GoalCard: View {
    let goal: Goal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SplitStep: View {
    @Binding var daysPerWeek: Int
    @Binding var split: Split

    var body: some View {
        VStack(spacing: 24) {
            Text("Training Schedule")
                .font(.title.bold())
                .padding(.top, 32)

            VStack(alignment: .leading, spacing: 12) {
                Text("Days per week")
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(3...6, id: \.self) { days in
                        Button {
                            daysPerWeek = days
                            // Auto-suggest split
                            switch days {
                            case 3: split = .fullBody
                            case 4: split = .upperLower
                            case 5, 6: split = .ppl
                            default: break
                            }
                        } label: {
                            Text("\(days)")
                                .font(.title2.bold())
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(daysPerWeek == days ? Color.blue : Color(.systemGray6))
                                )
                                .foregroundStyle(daysPerWeek == days ? .white : .primary)
                        }
                    }
                }
            }
            .padding(.horizontal)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Workout split")
                    .font(.headline)

                ForEach(Split.allCases.filter { $0 != .custom }) { s in
                    SplitCard(split: s, isSelected: split == s) {
                        split = s
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct SplitCard: View {
    let split: Split
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(split.rawValue)
                        .font(.headline)

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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LocationStep: View {
    @Binding var location: Location

    var body: some View {
        VStack(spacing: 24) {
            Text("Where do you train?")
                .font(.title.bold())
                .padding(.top, 32)

            VStack(spacing: 12) {
                ForEach(Location.allCases) { loc in
                    LocationCard(location: loc, isSelected: location == loc) {
                        location = loc
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct LocationCard: View {
    let location: Location
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: location.icon)
                    .font(.title)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.rawValue)
                        .font(.headline)

                    Text(location.description)
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EquipmentStep: View {
    let location: Location

    @Binding var hasAdjustableDumbbells: Bool
    @Binding var hasBarbell: Bool
    @Binding var hasRack: Bool
    @Binding var hasCables: Bool
    @Binding var hasPullUpBar: Bool
    @Binding var hasBands: Bool
    @Binding var hasBench: Bool
    @Binding var hasMachines: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Available Equipment")
                    .font(.title.bold())
                    .padding(.top, 32)

                Text("Select what you have access to")
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    EquipmentToggle(
                        title: "Barbell",
                        icon: "figure.strengthtraining.traditional",
                        isOn: $hasBarbell
                    )

                    EquipmentToggle(
                        title: "Squat Rack",
                        icon: "square.stack.3d.up.fill",
                        isOn: $hasRack
                    )

                    EquipmentToggle(
                        title: "Bench",
                        icon: "bed.double.fill",
                        isOn: $hasBench
                    )

                    EquipmentToggle(
                        title: "Dumbbells",
                        icon: "dumbbell.fill",
                        isOn: $hasAdjustableDumbbells
                    )

                    EquipmentToggle(
                        title: "Cable Machine",
                        icon: "cable.connector",
                        isOn: $hasCables
                    )

                    EquipmentToggle(
                        title: "Other Machines",
                        icon: "gearshape.fill",
                        isOn: $hasMachines
                    )

                    EquipmentToggle(
                        title: "Pull-up Bar",
                        icon: "figure.climbing",
                        isOn: $hasPullUpBar
                    )

                    EquipmentToggle(
                        title: "Resistance Bands",
                        icon: "lasso",
                        isOn: $hasBands
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

struct EquipmentToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44)
                    .foregroundStyle(isOn ? .blue : .secondary)

                Text(title)
                    .font(.body)

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isOn ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

struct CoachStep: View {
    @Binding var rpeFamiliarity: Bool
    @Binding var llmProvider: LLMProviderType
    @Binding var claudeAPIKey: String
    @Binding var openAIAPIKey: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("AI Coach Setup")
                    .font(.title.bold())
                    .padding(.top, 32)

                // RPE familiarity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Are you familiar with RPE?")
                        .font(.headline)

                    Text("Rate of Perceived Exertion (RPE) is a 1-10 scale measuring how hard a set felt. RPE 10 = failure, RPE 8 = 2 reps left.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("RPE Familiarity", selection: $rpeFamiliarity) {
                        Text("No, keep it simple").tag(false)
                        Text("Yes, I use RPE").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                Divider()

                // LLM Provider
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Provider")
                        .font(.headline)

                    Text("Choose how you want your coach to work")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(LLMProviderType.allCases) { provider in
                        ProviderCard(
                            provider: provider,
                            isSelected: llmProvider == provider
                        ) {
                            llmProvider = provider
                        }
                    }

                    if llmProvider == .claude {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Claude API Key")
                                .font(.subheadline)
                            SecureField("sk-ant-...", text: $claudeAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                        }
                        .padding(.top, 8)
                    }

                    if llmProvider == .openai {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OpenAI API Key")
                                .font(.subheadline)
                            SecureField("sk-...", text: $openAIAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

struct ProviderCard: View {
    let provider: LLMProviderType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: provider.icon)
                    .font(.title2)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .font(.headline)

                    Text(providerDescription)
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var providerDescription: String {
        switch provider {
        case .claude:
            return "Best reasoning, requires API key"
        case .openai:
            return "Fast responses, requires API key"
        case .offline:
            return "Rule-based, no API needed"
        }
    }
}

#Preview {
    OnboardingFlow()
        .modelContainer(for: [UserProfile.self, EquipmentProfile.self], inMemory: true)
}
