import SwiftUI
import SwiftData

struct PlanTemplatesSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]

    @State private var selectedTemplate: PlanTemplate?
    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(PlanTemplateLibrary.templates) { template in
                    PlanTemplateRow(template: template)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTemplate = template
                            showPreview = true
                        }
                }
            }
            .navigationTitle("Plan Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPreview) {
                if let template = selectedTemplate {
                    PlanTemplatePreviewSheet(
                        template: template,
                        onUse: {
                            usePlanTemplate(template)
                        }
                    )
                }
            }
        }
    }

    private func usePlanTemplate(_ template: PlanTemplate) {
        let plan = PlanTemplateLibrary.createPlan(
            from: template,
            exercises: exercises,
            in: modelContext
        )

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Template Row

struct PlanTemplateRow: View {
    let template: PlanTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: template.goal.icon)
                    .foregroundStyle(.blue)
            }
            
            Text(template.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                Label(template.durationText, systemImage: "calendar")
                Label(template.scheduleText, systemImage: "figure.strengthtraining.traditional")
                Label(template.split.rawValue, systemImage: "square.grid.2x2")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview Sheet

struct PlanTemplatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let template: PlanTemplate
    let onUse: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.title.bold())
                        
                        HStack(spacing: 12) {
                            Label(template.goal.rawValue, systemImage: template.goal.icon)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            
                            Label(template.durationText, systemImage: "calendar")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Capsule())
                            
                            Label(template.scheduleText, systemImage: "repeat")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .font(.caption)
                        
                        Text(template.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    
                    Divider()
                    
                    // Split info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Training Split")
                            .font(.headline)

                        Text(template.split.rawValue)
                            .font(.subheadline)

                        Text(template.split.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Workout exercises
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Workouts")
                            .font(.headline)

                        let uniqueWorkouts = Array(Set(template.workoutNames))
                        ForEach(uniqueWorkouts, id: \.self) { workoutName in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(workoutName)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())

                                let exercises = template.getExercises(for: workoutName)
                                if exercises.isEmpty {
                                    Text("No exercises defined")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .italic()
                                } else {
                                    ForEach(exercises.indices, id: \.self) { index in
                                        let exercise = exercises[index]
                                        HStack(spacing: 8) {
                                            Text("\(index + 1).")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 20, alignment: .leading)

                                            Text(exercise.name)
                                                .font(.caption)

                                            Spacer()

                                            Text("\(exercise.sets)×\(exercise.repsMin)-\(exercise.repsMax)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)

                                            Text("RPE \(Int(exercise.rpe))")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Divider()
                    
                    // Week breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Week Structure")
                            .font(.headline)
                        
                        ForEach(template.weekStructure, id: \.weekNumber) { week in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(week.weekType.color.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Text("\(week.weekNumber)")
                                        .font(.caption.bold())
                                        .foregroundStyle(week.weekType.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Week \(week.weekNumber)")
                                            .font(.subheadline.bold())
                                        
                                        Text(week.weekType.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(week.weekType.color.opacity(0.2))
                                            .foregroundStyle(week.weekType.color)
                                            .clipShape(Capsule())
                                    }
                                    
                                    if let notes = week.notes {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Use button
                    Button {
                        onUse()
                        dismiss()
                    } label: {
                        Text("Use This Template")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Template Preview")
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
    PlanTemplatesSheet()
        .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
