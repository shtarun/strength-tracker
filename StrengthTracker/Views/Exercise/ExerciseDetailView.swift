import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]

    let exercise: Exercise

    @State private var showPainFlagSheet = false
    @State private var showFormGuidance = false

    private var profile: UserProfile? { userProfiles.first }
    private var unitSystem: UnitSystem { profile?.unitSystem ?? .metric }

    private var exerciseHistory: [SetHistory] {
        sessions
            .sorted { $0.date > $1.date }
            .flatMap { session in
                session.sets
                    .filter { $0.exercise?.id == exercise.id && $0.isCompleted && $0.setType != .warmup }
                    .map { SetHistory(from: $0, date: session.date) }
            }
    }

    private var topSets: [SetHistory] {
        // Group by date and get best e1RM per day
        let grouped = Dictionary(grouping: exerciseHistory) { history in
            Calendar.current.startOfDay(for: history.date)
        }

        return grouped.compactMap { _, sets in
            sets.max { $0.e1RM < $1.e1RM }
        }.sorted { $0.date < $1.date }
    }

    private var currentE1RM: Double? {
        topSets.last?.e1RM
    }

    private var allTimeE1RM: Double? {
        topSets.map(\.e1RM).max()
    }

    private var recentTrend: String {
        guard topSets.count >= 2 else { return "Not enough data" }
        let recent = topSets.suffix(5)
        let first = recent.first!.e1RM
        let last = recent.last!.e1RM
        let change = ((last - first) / first) * 100

        if abs(change) < 1 {
            return "Stable"
        } else if change > 0 {
            return "+\(String(format: "%.1f", change))% trending up"
        } else {
            return "\(String(format: "%.1f", change))% trending down"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.title.bold())

                            Text(exercise.movementPattern.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            showPainFlagSheet = true
                        } label: {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                        }
                    }

                    // Muscles
                    HStack {
                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            Text(muscle.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }

                        ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                            Text(muscle.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Form Guidance Button
                    if exercise.hasFormGuidance {
                        HStack {
                            Spacer()
                            Button {
                                showFormGuidance = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                    Text("Form Tips")
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Current stats
                HStack(spacing: 16) {
                    StatBox(
                        title: "Current e1RM",
                        value: currentE1RM.map { unitSystem.formatWeight($0) } ?? "-"
                    )

                    StatBox(
                        title: "All-time Best",
                        value: allTimeE1RM.map { unitSystem.formatWeight($0) } ?? "-"
                    )

                    StatBox(
                        title: "Sessions",
                        value: "\(topSets.count)"
                    )
                }

                // Trend indicator
                HStack {
                    Image(systemName: recentTrend.contains("up") ? "arrow.up.right" : recentTrend.contains("down") ? "arrow.down.right" : "arrow.right")
                        .foregroundStyle(recentTrend.contains("up") ? .green : recentTrend.contains("down") ? .orange : .blue)

                    Text(recentTrend)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // e1RM Chart
                if !topSets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("e1RM Progress")
                            .font(.headline)

                        E1RMChart(data: topSets, unitSystem: unitSystem)
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Recent history
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)

                    if exerciseHistory.isEmpty {
                        Text("No history yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(Array(topSets.suffix(5).reversed().enumerated()), id: \.offset) { _, history in
                            HistoryRow(history: history, unitSystem: unitSystem)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPainFlagSheet) {
            PainFlagSheet(exercise: exercise)
        }
        .sheet(isPresented: $showFormGuidance) {
            FormGuidanceSheet(exercise: exercise)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct E1RMChart: View {
    let data: [SetHistory]
    let unitSystem: UnitSystem

    var body: some View {
        Chart {
            ForEach(data, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("e1RM", unitSystem.convert(kg: point.e1RM))
                )
                .foregroundStyle(Color.blue.gradient)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("e1RM", unitSystem.convert(kg: point.e1RM))
                )
                .foregroundStyle(Color.blue)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let history: SetHistory
    let unitSystem: UnitSystem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(history.date, format: .dateTime.month().day().year())
                    .font(.subheadline.bold())

                Text(history.setType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(unitSystem.formatWeight(history.weight)) × \(history.reps)")
                    .font(.subheadline.monospacedDigit())

                if let rpe = history.rpe {
                    Text("RPE \(rpe, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("e1RM: \(unitSystem.formatWeight(history.e1RM))")
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PainFlagSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    @State private var bodyPart: BodyPart = .chest
    @State private var severity: PainSeverity = .mild
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Body Part") {
                    Picker("Body Part", selection: $bodyPart) {
                        ForEach(BodyPart.allCases) { part in
                            Text(part.rawValue).tag(part)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("Severity") {
                    Picker("Severity", selection: $severity) {
                        ForEach(PainSeverity.allCases) { sev in
                            Text(sev.rawValue).tag(sev)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes (optional)") {
                    TextField("Describe the pain...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Flag Pain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let flag = PainFlag(
                            exercise: exercise,
                            bodyPart: bodyPart,
                            severity: severity,
                            notes: notes.isEmpty ? nil : notes
                        )
                        modelContext.insert(flag)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Form Guidance Sheet
struct FormGuidanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Form Cues Section
                    if !exercise.formCues.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Form Cues", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(exercise.formCues, id: \.self) { cue in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.green)
                                            .frame(width: 20)
                                        
                                        Text(cue)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Common Mistakes Section
                    if !exercise.commonMistakes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Common Mistakes", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(exercise.commonMistakes, id: \.self) { mistake in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "xmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.orange)
                                            .frame(width: 20)
                                        
                                        Text(mistake)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Equipment info
                    if !exercise.equipmentRequired.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Equipment Needed", systemImage: "dumbbell.fill")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            
                            HStack(spacing: 8) {
                                ForEach(exercise.equipmentRequired, id: \.self) { equipment in
                                    HStack(spacing: 4) {
                                        Image(systemName: equipment.icon)
                                            .font(.caption)
                                        Text(equipment.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Duration for mobility/cardio
                    if let duration = exercise.durationSeconds {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Recommended Duration", systemImage: "timer")
                                .font(.headline)
                                .foregroundStyle(.purple)
                            
                            Text(formatDuration(duration))
                                .font(.title2.bold())
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Form Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes) min"
            }
            return "\(minutes) min \(remainingSeconds) sec"
        }
        return "\(seconds) seconds"
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(
            exercise: Exercise(
                name: "Bench Press",
                movementPattern: .horizontalPush,
                primaryMuscles: [.chest],
                secondaryMuscles: [.frontDelt, .triceps],
                equipmentRequired: [.barbell, .bench, .rack]
            )
        )
    }
    .modelContainer(for: [UserProfile.self, WorkoutSession.self], inMemory: true)
}
