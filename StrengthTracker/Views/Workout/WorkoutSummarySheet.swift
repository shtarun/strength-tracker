import SwiftUI

struct WorkoutSummarySheet: View {
    let template: WorkoutTemplate
    let exerciseSets: [UUID: [WorkoutSet]]
    let startTime: Date
    let provider: LLMProviderType
    let onSave: () -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var insight: InsightResponse?
    @State private var isLoadingInsight = false

    private var duration: Int {
        Int(Date().timeIntervalSince(startTime) / 60)
    }

    private var totalSets: Int {
        exerciseSets.values.flatMap { $0 }.filter { $0.isCompleted }.count
    }

    private var totalVolume: Double {
        exerciseSets.values.flatMap { $0 }
            .filter { $0.isCompleted }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var exerciseSummaries: [(name: String, sets: Int, topWeight: Double, topReps: Int)] {
        template.sortedExercises.compactMap { templateEx -> (String, Int, Double, Int)? in
            guard let exercise = templateEx.exercise,
                  let sets = exerciseSets[exercise.id] else { return nil }

            let completedSets = sets.filter { $0.isCompleted }
            guard !completedSets.isEmpty else { return nil }

            let topSet = completedSets.max { $0.weight < $1.weight }!

            return (exercise.name, completedSets.count, topSet.weight, topSet.reps)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("Workout Complete!")
                            .font(.title.bold())

                        Text(template.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Stats
                    HStack(spacing: 20) {
                        SummaryStat(title: "Duration", value: "\(duration) min", icon: "clock.fill")
                        SummaryStat(title: "Sets", value: "\(totalSets)", icon: "number")
                        SummaryStat(title: "Volume", value: formatVolume(totalVolume), icon: "scalemass.fill")
                    }

                    Divider()

                    // Exercise breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercise Summary")
                            .font(.headline)

                        ForEach(exerciseSummaries, id: \.name) { summary in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(summary.name)
                                        .font(.subheadline.bold())

                                    Text("\(summary.sets) sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(Int(summary.topWeight))kg × \(summary.topReps)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // AI Insight
                    if let insight = insight {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Coach's Insight", systemImage: "brain.head.profile")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(insight.insight)
                                    .font(.body)

                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text(insight.action)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else if isLoadingInsight {
                        HStack {
                            ProgressView()
                            Text("Generating insight...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        onDiscard()
                    }
                    .foregroundStyle(.red)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .bold()
                }
            }
        }
        .onAppear {
            loadInsight()
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }

    private func loadInsight() {
        // Generate insight using LLM or offline engine
        isLoadingInsight = true

        Task {
            let summary = SessionSummary(
                templateName: template.name,
                exercises: exerciseSummaries.map { ex in
                    ExerciseSummary(
                        name: ex.name,
                        topSet: SetSummary(
                            weight: ex.topWeight,
                            reps: ex.topReps,
                            rpe: nil,
                            targetReps: ex.topReps
                        ),
                        backoffSets: [],
                        targetHit: true,
                        e1RM: E1RMCalculator.calculate(weight: ex.topWeight, reps: ex.topReps),
                        previousE1RM: nil
                    )
                },
                readiness: ReadinessContext(energy: "OK", soreness: "None"),
                totalVolume: totalVolume,
                duration: duration
            )

            do {
                insight = try await LLMService.shared.generateInsight(
                    session: summary,
                    provider: provider
                )
            } catch {
                print("Failed to generate insight: \(error)")
            }

            isLoadingInsight = false
        }
    }
}

struct SummaryStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)

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

#Preview {
    WorkoutSummarySheet(
        template: WorkoutTemplate(name: "Upper A", dayNumber: 1),
        exerciseSets: [:],
        startTime: Date().addingTimeInterval(-3600),
        provider: .offline,
        onSave: {},
        onDiscard: {}
    )
}
