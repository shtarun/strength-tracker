import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: WorkoutPlan
    
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var selectedWeek: PlanWeek?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    PlanHeaderCard(plan: plan)
                    
                    // Action buttons
                    PlanActionButtons(
                        plan: plan,
                        onActivate: activatePlan,
                        onDeactivate: deactivatePlan,
                        onReset: resetPlan
                    )
                    
                    // Weeks list
                    WeeksSection(
                        plan: plan,
                        onSelectWeek: { week in
                            selectedWeek = week
                        }
                    )
                }
                .padding()
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit Plan", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Plan", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditPlanSheet(plan: plan)
            }
            .sheet(item: $selectedWeek) { week in
                WeekDetailView(week: week)
            }
            .confirmationDialog(
                "Delete Plan?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deletePlan()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(plan.name)\" and all its weeks. This cannot be undone.")
            }
        }
    }
    
    private func activatePlan() {
        PlanProgressService.shared.activatePlan(plan, in: modelContext)
    }
    
    private func deactivatePlan() {
        plan.isActive = false
        try? modelContext.save()
    }
    
    private func resetPlan() {
        PlanProgressService.shared.resetPlan(plan, in: modelContext)
    }
    
    private func deletePlan() {
        modelContext.delete(plan)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Header Card

struct PlanHeaderCard: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Goal and duration
            HStack {
                Label(plan.goal.rawValue, systemImage: plan.goal.icon)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                
                Label("\(plan.durationWeeks) weeks", systemImage: "calendar")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                
                Label("\(plan.workoutsPerWeek)x/week", systemImage: "repeat")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Description
            if let description = plan.planDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Progress
            if plan.isActive || plan.startDate != nil {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(Int(plan.progressPercentage * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: plan.progressPercentage)
                        .tint(.blue)
                    
                    HStack {
                        if let start = plan.startDate {
                            Text("Started: \(start.formatted(date: .abbreviated, time: .omitted))")
                        }
                        Spacer()
                        if let end = plan.estimatedEndDate {
                            Text("Est. end: \(end.formatted(date: .abbreviated, time: .omitted))")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Action Buttons

struct PlanActionButtons: View {
    let plan: WorkoutPlan
    let onActivate: () -> Void
    let onDeactivate: () -> Void
    let onReset: () -> Void
    
    @State private var showResetConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            if plan.isActive {
                Button {
                    onDeactivate()
                } label: {
                    Label("Pause Plan", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button {
                    onActivate()
                } label: {
                    Label(plan.startDate == nil ? "Start Plan" : "Resume Plan", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            if plan.startDate != nil {
                Button {
                    showResetConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .padding()
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .confirmationDialog(
                    "Reset Plan?",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset Progress", role: .destructive) {
                        onReset()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will reset all progress and allow you to start the plan fresh.")
                }
            }
        }
    }
}

// MARK: - Weeks Section

struct WeeksSection: View {
    let plan: WorkoutPlan
    let onSelectWeek: (PlanWeek) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weeks")
                .font(.headline)
            
            ForEach(plan.sortedWeeks) { week in
                WeekRow(week: week, plan: plan)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectWeek(week)
                    }
            }
        }
    }
}

// MARK: - Week Row

struct WeekRow: View {
    let week: PlanWeek
    let plan: WorkoutPlan
    
    private var isCurrentWeek: Bool {
        plan.isActive && plan.currentWeek == week.weekNumber
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: week.isCompleted ? "checkmark" : "\(week.weekNumber).circle.fill")
                    .font(.title3)
                    .foregroundStyle(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Week \(week.weekNumber)")
                        .font(.headline)
                    
                    if isCurrentWeek {
                        Text("CURRENT")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: week.weekType.icon)
                        Text(week.weekType.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(week.weekType.color)
                }
                
                Text(week.summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(isCurrentWeek ? Color.blue.opacity(0.05) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentWeek ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private var statusColor: Color {
        if week.isCompleted {
            return .green
        } else if isCurrentWeek {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Edit Plan Sheet

struct EditPlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: WorkoutPlan
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Details") {
                    TextField("Name", text: $plan.name)
                    
                    TextField("Description", text: Binding(
                        get: { plan.planDescription ?? "" },
                        set: { plan.planDescription = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                Section("Settings") {
                    Picker("Goal", selection: $plan.goal) {
                        ForEach(Goal.allCases) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    
                    Stepper("Workouts per week: \(plan.workoutsPerWeek)", value: $plan.workoutsPerWeek, in: 2...7)
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        plan.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutPlan.self, configurations: config)
    
    let plan = WorkoutPlan(
        name: "Strength Block",
        planDescription: "4-week strength building program",
        durationWeeks: 4,
        workoutsPerWeek: 4,
        goal: .strength
    )
    
    for i in 1...4 {
        let weekType: WeekType = i == 4 ? .deload : .regular
        let week = PlanWeek(weekNumber: i, weekType: weekType)
        week.plan = plan
        plan.weeks.append(week)
    }
    
    container.mainContext.insert(plan)
    
    return PlanDetailView(plan: plan)
        .modelContainer(container)
}
