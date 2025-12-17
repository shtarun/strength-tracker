import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var showEquipmentEditor = false
    @State private var showAPISettings = false
    @State private var showResetConfirmation = false
    @State private var showDataManagement = false

    private var profile: UserProfile? { userProfiles.first }

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profile {
                    // User Info
                    Section("Profile") {
                        HStack {
                            Text("Name")
                            Spacer()
                            TextField("Name", text: Binding(
                                get: { profile.name },
                                set: { profile.name = $0 }
                            ))
                            .multilineTextAlignment(.trailing)
                        }

                        Picker("Goal", selection: Binding(
                            get: { profile.goal },
                            set: { profile.goal = $0 }
                        )) {
                            ForEach(Goal.allCases) { goal in
                                Text(goal.rawValue).tag(goal)
                            }
                        }

                        Picker("Split", selection: Binding(
                            get: { profile.preferredSplit },
                            set: { profile.preferredSplit = $0 }
                        )) {
                            ForEach(Split.allCases.filter { $0 != .custom }) { split in
                                Text(split.rawValue).tag(split)
                            }
                        }

                        Stepper("Days/Week: \(profile.daysPerWeek)", value: Binding(
                            get: { profile.daysPerWeek },
                            set: { profile.daysPerWeek = $0 }
                        ), in: 2...7)
                    }

                    // Units & Preferences
                    Section("Preferences") {
                        Picker("Units", selection: Binding(
                            get: { profile.unitSystem },
                            set: { profile.unitSystem = $0 }
                        )) {
                            ForEach(UnitSystem.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        
                        Picker("Appearance", selection: Binding(
                            get: { profile.appearanceMode },
                            set: { profile.appearanceMode = $0 }
                        )) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                            }
                        }

                        Toggle("Use RPE", isOn: Binding(
                            get: { profile.rpeFamiliarity },
                            set: { profile.rpeFamiliarity = $0 }
                        ))

                        Stepper("Rest Timer: \(profile.defaultRestTime / 60):\(String(format: "%02d", profile.defaultRestTime % 60))", value: Binding(
                            get: { profile.defaultRestTime },
                            set: { profile.defaultRestTime = $0 }
                        ), in: 60...300, step: 15)
                    }

                    // Equipment
                    Section {
                        Button {
                            showEquipmentEditor = true
                        } label: {
                            HStack {
                                Text("Equipment Profile")
                                Spacer()
                                Text(profile.equipmentProfile?.location.rawValue ?? "Not set")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // AI Coach
                    Section("AI Coach") {
                        Picker("Provider", selection: Binding(
                            get: { profile.preferredLLMProvider },
                            set: { profile.preferredLLMProvider = $0 }
                        )) {
                            ForEach(LLMProviderType.allCases) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }

                        Button {
                            showAPISettings = true
                        } label: {
                            HStack {
                                Text("API Keys")
                                Spacer()
                                Text(apiKeyStatus)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Data
                    Section("Data") {
                        Button {
                            showDataManagement = true
                        } label: {
                            HStack {
                                Label("Export & Import", systemImage: "arrow.up.arrow.down.circle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Text("Reset All Data")
                        }
                    }

                    // About
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEquipmentEditor) {
                if let profile = profile {
                    EquipmentEditorSheet(equipment: profile.equipmentProfile ?? EquipmentProfile())
                }
            }
            .sheet(isPresented: $showAPISettings) {
                if let profile = profile {
                    APISettingsSheet(profile: profile)
                }
            }
            .sheet(isPresented: $showDataManagement) {
                DataManagementView()
            }
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetData()
                }
            } message: {
                Text("This will delete all your workout history and settings. This action cannot be undone.")
            }
            .onChange(of: profile?.preferredLLMProvider) { _, newValue in
                if let profile = profile {
                    LLMService.shared.configure(
                        claudeAPIKey: profile.claudeAPIKey,
                        openAIAPIKey: profile.openAIAPIKey
                    )
                }
            }
        }
    }

    private var apiKeyStatus: String {
        guard let profile = profile else { return "Not set" }

        switch profile.preferredLLMProvider {
        case .claude:
            return profile.claudeAPIKey?.isEmpty == false ? "Configured" : "Not set"
        case .openai:
            return profile.openAIAPIKey?.isEmpty == false ? "Configured" : "Not set"
        case .offline:
            return "Not required"
        }
    }

    private func resetData() {
        // Delete all data
        try? modelContext.delete(model: WorkoutSession.self)
        try? modelContext.delete(model: WorkoutSet.self)
        try? modelContext.delete(model: WorkoutTemplate.self)
        try? modelContext.delete(model: ExerciseTemplate.self)
        try? modelContext.delete(model: PainFlag.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.delete(model: EquipmentProfile.self)
        try? modelContext.delete(model: Exercise.self)

        try? modelContext.save()
    }
}

struct EquipmentEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var equipment: EquipmentProfile

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("Primary Location", selection: $equipment.location) {
                        ForEach(Location.allCases) { location in
                            Text(location.rawValue).tag(location)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Equipment") {
                    Toggle("Barbell", isOn: $equipment.hasBarbell)
                    Toggle("Squat Rack", isOn: $equipment.hasRack)
                    Toggle("Bench", isOn: $equipment.hasBench)
                    Toggle("Dumbbells", isOn: $equipment.hasAdjustableDumbbells)
                    Toggle("Cable Machine", isOn: $equipment.hasCables)
                    Toggle("Other Machines", isOn: $equipment.hasMachines)
                    Toggle("Pull-up Bar", isOn: $equipment.hasPullUpBar)
                    Toggle("Resistance Bands", isOn: $equipment.hasBands)
                }

                Section("Plates") {
                    Toggle("Microplates (1.25kg)", isOn: $equipment.hasMicroplates)

                    // Could add custom plate configuration here
                }
            }
            .navigationTitle("Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct APISettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    @State private var claudeKey: String
    @State private var openAIKey: String
    @State private var showClaudeKey = false
    @State private var showOpenAIKey = false

    init(profile: UserProfile) {
        self.profile = profile
        self._claudeKey = State(initialValue: profile.claudeAPIKey ?? "")
        self._openAIKey = State(initialValue: profile.openAIAPIKey ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Claude (Anthropic)")
                            .font(.headline)

                        HStack {
                            if showClaudeKey {
                                TextField("sk-ant-...", text: $claudeKey)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("sk-ant-...", text: $claudeKey)
                                    .textContentType(.password)
                            }

                            Button {
                                showClaudeKey.toggle()
                            } label: {
                                Image(systemName: showClaudeKey ? "eye.slash" : "eye")
                            }
                        }
                    }
                } footer: {
                    Text("Get your API key from console.anthropic.com")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI")
                            .font(.headline)

                        HStack {
                            if showOpenAIKey {
                                TextField("sk-...", text: $openAIKey)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("sk-...", text: $openAIKey)
                                    .textContentType(.password)
                            }

                            Button {
                                showOpenAIKey.toggle()
                            } label: {
                                Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                            }
                        }
                    }
                } footer: {
                    Text("Get your API key from platform.openai.com")
                }

                Section {
                    Text("API keys are stored locally on your device and never sent to our servers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("API Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile.claudeAPIKey = claudeKey.isEmpty ? nil : claudeKey
                        profile.openAIAPIKey = openAIKey.isEmpty ? nil : openAIKey

                        LLMService.shared.configure(
                            claudeAPIKey: profile.claudeAPIKey,
                            openAIAPIKey: profile.openAIAPIKey
                        )

                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, EquipmentProfile.self], inMemory: true)
}
