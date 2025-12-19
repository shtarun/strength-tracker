import SwiftUI
import SwiftData

struct PlansListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.updatedAt, order: .reverse) private var plans: [WorkoutPlan]
    @Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]
    
    @State private var showCreateSheet = false
    @State private var showTemplatesSheet = false
    @State private var selectedPlan: WorkoutPlan?
    
    private var activePlan: WorkoutPlan? {
        plans.first { $0.isActive }
    }
    
    private var inactivePlans: [WorkoutPlan] {
        plans.filter { !$0.isActive }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Active plan section
                if let active = activePlan {
                    Section {
                        ActivePlanCard(plan: active)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlan = active
                            }
                    } header: {
                        Label("Active Plan", systemImage: "bolt.fill")
                    }
                }
                
                // Other plans section
                if !inactivePlans.isEmpty {
                    Section {
                        ForEach(inactivePlans) { plan in
                            PlanRow(plan: plan)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPlan = plan
                                }
                        }
                        .onDelete(perform: deletePlans)
                    } header: {
                        Label("My Plans", systemImage: "list.bullet.rectangle")
                    }
                }
                
                // Create new plan section
                Section {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label("Create New Plan", systemImage: "plus.circle.fill")
                    }
                    
                    Button {
                        showTemplatesSheet = true
                    } label: {
                        Label("Browse Plan Templates", systemImage: "book.fill")
                    }
                }
                
                // Empty state
                if plans.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Workout Plans",
                            systemImage: "calendar.badge.plus",
                            description: Text("Create a plan to organize your training into weeks with progression and deload phases.")
                        )
                    }
                }
            }
            .navigationTitle("Workout Plans")
            .sheet(isPresented: $showCreateSheet) {
                CreatePlanSheet()
            }
            .sheet(isPresented: $showTemplatesSheet) {
                PlanTemplatesSheet()
            }
            .sheet(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
        }
    }
    
    private func deletePlans(at offsets: IndexSet) {
        for index in offsets {
            let plan = inactivePlans[index]
            modelContext.delete(plan)
        }
        try? modelContext.save()
    }
}

// MARK: - Active Plan Card

struct ActivePlanCard: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)
                    
                    if let week = plan.currentPlanWeek {
                        HStack(spacing: 4) {
                            Image(systemName: week.weekType.icon)
                                .foregroundStyle(week.weekType.color)
                            Text("Week \(plan.currentWeek) of \(plan.durationWeeks)")
                                .font(.subheadline)
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(week.weekType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(week.weekType.color)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            
            // Progress bar
            ProgressView(value: plan.progressPercentage)
                .tint(.blue)
            
            HStack {
                Text("\(Int(plan.progressPercentage * 100))% complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(plan.completedWorkoutsThisWeek)/\(plan.workoutsPerWeek) this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plan Row

struct PlanRow: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: plan.goal.icon)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                Label("\(plan.durationWeeks)w", systemImage: "calendar")
                Label("\(plan.workoutsPerWeek)x/wk", systemImage: "figure.strengthtraining.traditional")
                
                Spacer()
                
                Text(plan.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PlansListView()
        .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
