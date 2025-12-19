import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutPlan.updatedAt, order: .reverse) private var plans: [WorkoutPlan]

    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showEditor = false
    @State private var showPlansView = false
    
    private var activePlan: WorkoutPlan? {
        plans.first { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            List {
                // Active plan section
                if let plan = activePlan {
                    Section {
                        ActivePlanBanner(plan: plan)
                            .onTapGesture {
                                showPlansView = true
                            }
                    }
                }
                
                // Plans section
                Section {
                    NavigationLink {
                        PlansListView()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text("Workout Plans")
                                    .font(.headline)
                                Text("\(plans.count) plans")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Label("Programs", systemImage: "list.bullet.rectangle")
                }
                
                // Templates section
                Section {
                    ForEach(templates) { template in
                        TemplateRow(template: template)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                                showEditor = true
                            }
                    }
                    .onDelete(perform: deleteTemplates)
                    .onMove(perform: moveTemplates)
                } header: {
                    Label("Workout Templates", systemImage: "doc.text")
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let newTemplate = WorkoutTemplate(
                            name: "New Workout",
                            dayNumber: templates.count + 1
                        )
                        modelContext.insert(newTemplate)
                        selectedTemplate = newTemplate
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                if let template = selectedTemplate {
                    TemplateEditorView(template: template)
                }
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = templates[index]
            modelContext.delete(template)
        }
        
        // Renumber remaining templates
        let remainingTemplates = templates.filter { template in
            !offsets.contains(templates.firstIndex(of: template) ?? -1)
        }
        for (index, template) in remainingTemplates.enumerated() {
            template.dayNumber = index + 1
        }
        
        try? modelContext.save()
    }

    private func moveTemplates(from source: IndexSet, to destination: Int) {
        var reorderedTemplates = templates
        reorderedTemplates.move(fromOffsets: source, toOffset: destination)

        for (index, template) in reorderedTemplates.enumerated() {
            template.dayNumber = index + 1
        }

        try? modelContext.save()
    }
}

// MARK: - Active Plan Banner

struct ActivePlanBanner: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text("Active Plan")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Text(plan.name)
                .font(.headline)
            
            if let week = plan.currentPlanWeek {
                HStack {
                    Image(systemName: week.weekType.icon)
                        .foregroundStyle(week.weekType.color)
                    Text("Week \(plan.currentWeek) of \(plan.durationWeeks)")
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(week.weekType.rawValue)
                        .foregroundStyle(week.weekType.color)
                }
                .font(.subheadline)
            }
            
            ProgressView(value: plan.progressPercentage)
                .tint(.blue)
            
            HStack {
                Text("\(Int(plan.progressPercentage * 100))% complete")
                Spacer()
                Text("\(plan.completedWorkoutsThisWeek)/\(plan.workoutsPerWeek) this week")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Day \(template.dayNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())

                Spacer()

                Text("\(template.targetDuration) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(template.name)
                .font(.headline)

            // Exercise preview
            HStack {
                Text(template.sortedExercises.prefix(3).compactMap { $0.exercise?.name }.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if template.exercises.count > 3 {
                    Text("+\(template.exercises.count - 3)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]

    @Bindable var template: WorkoutTemplate

    @State private var showExercisePicker = false
    @State private var showPrescriptionEditor = false
    @State private var selectedExerciseTemplate: ExerciseTemplate?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $template.name)

                    Stepper("Duration: \(template.targetDuration) min", value: $template.targetDuration, in: 30...120, step: 15)
                }

                Section("Exercises") {
                    ForEach(template.sortedExercises) { exerciseTemplate in
                        ExerciseTemplateRow(
                            exerciseTemplate: exerciseTemplate,
                            onTap: {
                                selectedExerciseTemplate = exerciseTemplate
                                showPrescriptionEditor = true
                            }
                        )
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Template")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    modelContext.delete(template)
                    try? modelContext.save()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete \"\(template.name)\" and all its exercises.")
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet(
                    exercises: allExercises,
                    existingExercises: template.exercises.compactMap { $0.exercise },
                    onSelect: { exercise in
                        addExercise(exercise)
                    }
                )
            }
            .sheet(isPresented: $showPrescriptionEditor) {
                if let exerciseTemplate = selectedExerciseTemplate {
                    PrescriptionEditorSheet(exerciseTemplate: exerciseTemplate)
                }
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let exerciseTemplate = ExerciseTemplate(
            exercise: exercise,
            orderIndex: template.exercises.count,
            prescription: exercise.defaultProgressionType == .topSetBackoff ? .default : .hypertrophy
        )
        exerciseTemplate.template = template
        template.exercises.append(exerciseTemplate)
        modelContext.insert(exerciseTemplate)
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = template.sortedExercises
        for index in offsets {
            let exerciseTemplate = sorted[index]
            template.exercises.removeAll { $0.id == exerciseTemplate.id }
            modelContext.delete(exerciseTemplate)
        }
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = template.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)

        for (index, exerciseTemplate) in sorted.enumerated() {
            exerciseTemplate.orderIndex = index
        }
    }
}

struct ExerciseTemplateRow: View {
    let exerciseTemplate: ExerciseTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(exerciseTemplate.exercise?.name ?? "Unknown")
                            .font(.body)

                        if exerciseTemplate.isOptional {
                            Text("Optional")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }

                    Text(prescriptionSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var prescriptionSummary: String {
        let p = exerciseTemplate.prescription
        switch p.progressionType {
        case .topSetBackoff:
            return "1×\(p.topSetRepsRange) @\(Int(p.topSetRPECap)) + \(p.backoffSets)×\(p.backoffRepsRange)"
        case .doubleProgression, .straightSets:
            return "\(p.workingSets)×\(p.topSetRepsRange) @\(Int(p.topSetRPECap))"
        }
    }
}

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exercises: [Exercise]
    let existingExercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedPattern: MovementPattern?

    private var filteredExercises: [Exercise] {
        var result = exercises.filter { exercise in
            !existingExercises.contains { $0.id == exercise.id }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        if let pattern = selectedPattern {
            result = result.filter { $0.movementPattern == pattern }
        }

        return result.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pattern filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "All", isSelected: selectedPattern == nil) {
                            selectedPattern = nil
                        }

                        ForEach(MovementPattern.allCases) { pattern in
                            FilterChip(title: pattern.rawValue, isSelected: selectedPattern == pattern) {
                                selectedPattern = pattern
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                List(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.body)

                            HStack {
                                Text(exercise.movementPattern.rawValue)
                                Text("•")
                                Text(exercise.primaryMuscles.map(\.rawValue).joined(separator: ", "))
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct PrescriptionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var exerciseTemplate: ExerciseTemplate

    @State private var prescription: Prescription

    init(exerciseTemplate: ExerciseTemplate) {
        self.exerciseTemplate = exerciseTemplate
        self._prescription = State(initialValue: exerciseTemplate.prescription)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Progression Type") {
                    Picker("Type", selection: $prescription.progressionType) {
                        ForEach(ProgressionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                if prescription.progressionType == .topSetBackoff {
                    Section("Top Set") {
                        Stepper("Min Reps: \(prescription.topSetRepsMin)", value: $prescription.topSetRepsMin, in: 1...12)
                        Stepper("Max Reps: \(prescription.topSetRepsMax)", value: $prescription.topSetRepsMax, in: prescription.topSetRepsMin...20)
                        Stepper("RPE Cap: \(prescription.topSetRPECap, specifier: "%.1f")", value: $prescription.topSetRPECap, in: 6...10, step: 0.5)
                    }

                    Section("Backoff Sets") {
                        Stepper("Sets: \(prescription.backoffSets)", value: $prescription.backoffSets, in: 0...6)
                        Stepper("Min Reps: \(prescription.backoffRepsMin)", value: $prescription.backoffRepsMin, in: 1...20)
                        Stepper("Max Reps: \(prescription.backoffRepsMax)", value: $prescription.backoffRepsMax, in: prescription.backoffRepsMin...30)

                        HStack {
                            Text("Load Drop")
                            Spacer()
                            Text("\(Int(prescription.backoffLoadDropPercent * 100))%")
                        }
                        Slider(value: $prescription.backoffLoadDropPercent, in: 0.05...0.20, step: 0.01)
                    }
                } else {
                    Section("Working Sets") {
                        Stepper("Sets: \(prescription.workingSets)", value: $prescription.workingSets, in: 1...6)
                        Stepper("Min Reps: \(prescription.topSetRepsMin)", value: $prescription.topSetRepsMin, in: 1...20)
                        Stepper("Max Reps: \(prescription.topSetRepsMax)", value: $prescription.topSetRepsMax, in: prescription.topSetRepsMin...30)
                        Stepper("RPE Cap: \(prescription.topSetRPECap, specifier: "%.1f")", value: $prescription.topSetRPECap, in: 6...10, step: 0.5)
                    }
                }

                Section {
                    Toggle("Optional Exercise", isOn: $exerciseTemplate.isOptional)
                } footer: {
                    Text("Optional exercises may be skipped when time is limited")
                }
            }
            .navigationTitle(exerciseTemplate.exercise?.name ?? "Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        exerciseTemplate.prescription = prescription
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TemplatesView()
        .modelContainer(for: [WorkoutTemplate.self, Exercise.self], inMemory: true)
}
