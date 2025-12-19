import SwiftUI
import SwiftData

struct CreatePlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]
    @Query private var userProfiles: [UserProfile]
    
    @State private var planName = ""
    @State private var planDescription = ""
    @State private var durationWeeks = 4
    @State private var workoutsPerWeek = 4
    @State private var goal: Goal = .both
    @State private var includeDeloads = true
    @State private var deloadFrequency = 4 // Every N weeks
    
    @State private var showAIGenerator = false
    
    private var profile: UserProfile? { userProfiles.first }
    private var canUseAI: Bool {
        profile?.preferredLLMProvider != .offline
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Quick options
                Section {
                    Button {
                        showAIGenerator = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading) {
                                Text("Generate with AI")
                                    .font(.headline)
                                Text("Create a complete plan automatically")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!canUseAI)
                    
                    if !canUseAI {
                        Text("Enable an AI provider in Settings to use this feature")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Plan Details") {
                    TextField("Plan Name", text: $planName)
                    
                    TextField("Description (optional)", text: $planDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Duration") {
                    Stepper("Duration: \(durationWeeks) weeks", value: $durationWeeks, in: 1...16)
                    
                    Stepper("Workouts per week: \(workoutsPerWeek)", value: $workoutsPerWeek, in: 2...7)
                }
                
                Section("Goal") {
                    Picker("Primary Goal", selection: $goal) {
                        ForEach(Goal.allCases) { g in
                            Label(g.rawValue, systemImage: g.icon).tag(g)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Deload Weeks") {
                    Toggle("Include Deload Weeks", isOn: $includeDeloads)
                    
                    if includeDeloads {
                        Stepper("Every \(deloadFrequency) weeks", value: $deloadFrequency, in: 2...6)
                        
                        Text("Deload weeks reduce intensity to 60% and volume to 50% for recovery.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Preview
                Section("Week Structure Preview") {
                    ForEach(1...min(durationWeeks, 8), id: \.self) { week in
                        let isDeload = includeDeloads && week % deloadFrequency == 0
                        let weekType: WeekType = isDeload ? .deload : .regular
                        
                        HStack {
                            Image(systemName: weekType.icon)
                                .foregroundStyle(weekType.color)
                            Text("Week \(week)")
                            Spacer()
                            Text(weekType.rawValue)
                                .font(.caption)
                                .foregroundStyle(weekType.color)
                        }
                    }
                    
                    if durationWeeks > 8 {
                        Text("+ \(durationWeeks - 8) more weeks...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPlan()
                    }
                    .disabled(planName.isEmpty)
                }
            }
            .sheet(isPresented: $showAIGenerator) {
                AIPlanGeneratorSheet(onPlanCreated: {
                    // Dismiss this sheet too when AI plan is created
                    dismiss()
                })
            }
        }
    }
    
    private func createPlan() {
        let plan = WorkoutPlan(
            name: planName,
            planDescription: planDescription.isEmpty ? nil : planDescription,
            durationWeeks: durationWeeks,
            workoutsPerWeek: workoutsPerWeek,
            goal: goal
        )
        
        // Create weeks
        for weekNum in 1...durationWeeks {
            let isDeload = includeDeloads && weekNum % deloadFrequency == 0
            let weekType: WeekType = isDeload ? .deload : .regular
            
            let week = PlanWeek(
                weekNumber: weekNum,
                weekType: weekType,
                templates: templates // Link all existing templates
            )
            week.plan = plan
            plan.weeks.append(week)
        }
        
        modelContext.insert(plan)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CreatePlanSheet()
        .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
