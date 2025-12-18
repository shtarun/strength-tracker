import SwiftUI
import SwiftData

struct WeekDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.dayNumber) private var allTemplates: [WorkoutTemplate]
    
    @Bindable var week: PlanWeek
    
    @State private var showTemplateSelector = false
    
    var body: some View {
        NavigationStack {
            List {
                // Week info section
                Section {
                    HStack {
                        Image(systemName: week.weekType.icon)
                            .font(.title2)
                            .foregroundStyle(week.weekType.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week \(week.weekNumber)")
                                .font(.headline)
                            Text(week.weekType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(week.weekType.color)
                        }
                        
                        Spacer()
                        
                        if week.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    // Week type picker
                    Picker("Week Type", selection: $week.weekType) {
                        ForEach(WeekType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .onChange(of: week.weekType) { oldValue, newValue in
                        // Update modifiers when week type changes
                        week.intensityModifier = newValue.intensityModifier
                        week.volumeModifier = newValue.volumeModifier
                        week.notes = newValue.coachingNotes
                    }
                }
                
                // Modifiers section
                Section("Intensity & Volume") {
                    HStack {
                        Text("Intensity")
                        Spacer()
                        Text("\(Int(week.intensityModifier * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $week.intensityModifier, in: 0.5...1.2, step: 0.05)
                    
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(week.volumeModifier * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $week.volumeModifier, in: 0.3...1.2, step: 0.05)
                    
                    Text(week.weekType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Notes section
                Section("Coaching Notes") {
                    TextField("Notes for this week", text: Binding(
                        get: { week.notes ?? "" },
                        set: { week.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                // Templates section
                Section {
                    ForEach(week.sortedTemplates) { template in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.headline)
                                Text("Day \(template.dayNumber) • \(template.targetDuration) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                removeTemplate(template)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Button {
                        showTemplateSelector = true
                    } label: {
                        Label("Add Workout Template", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Workouts (\(week.workoutCount))")
                } footer: {
                    Text("Templates are shared by reference. Changes to a template will affect all weeks using it.")
                }
            }
            .navigationTitle("Week \(week.weekNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTemplateSelector) {
                TemplateSelector(
                    selectedTemplates: week.templates,
                    allTemplates: allTemplates,
                    onSelect: { template in
                        addTemplate(template)
                    }
                )
            }
        }
    }
    
    private func addTemplate(_ template: WorkoutTemplate) {
        if !week.templates.contains(where: { $0.id == template.id }) {
            week.templates.append(template)
        }
    }
    
    private func removeTemplate(_ template: WorkoutTemplate) {
        week.templates.removeAll { $0.id == template.id }
    }
}

// MARK: - Template Selector

struct TemplateSelector: View {
    @Environment(\.dismiss) private var dismiss
    let selectedTemplates: [WorkoutTemplate]
    let allTemplates: [WorkoutTemplate]
    let onSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allTemplates) { template in
                    let isSelected = selectedTemplates.contains { $0.id == template.id }
                    
                    Button {
                        if !isSelected {
                            onSelect(template)
                        }
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundStyle(isSelected ? .secondary : .primary)
                                Text("\(template.exercises.count) exercises • \(template.targetDuration) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(isSelected)
                }
            }
            .navigationTitle("Add Template")
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PlanWeek.self, configurations: config)
    
    let week = PlanWeek(weekNumber: 2, weekType: .regular)
    container.mainContext.insert(week)
    
    return WeekDetailView(week: week)
        .modelContainer(container)
}
