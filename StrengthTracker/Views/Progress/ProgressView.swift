import SwiftUI
import SwiftData
import Charts

struct ProgressView_Custom: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var userProfiles: [UserProfile]
    @Query private var exercises: [Exercise]

    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedExercise: Exercise?
    @State private var showWeeklyReview = false

    private var profile: UserProfile? { userProfiles.first }
    private var unitSystem: UnitSystem { profile?.unitSystem ?? .metric }

    private var compoundExercises: [Exercise] {
        exercises.filter { $0.isCompound }.sorted { $0.name < $1.name }
    }

    private var filteredSessions: [WorkoutSession] {
        let cutoffDate = selectedTimeRange.cutoffDate
        return sessions.filter { $0.date >= cutoffDate && $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Weekly summary
                    WeeklySummaryCard(sessions: filteredSessions)

                    // Volume chart
                    VolumeChartCard(
                        sessions: filteredSessions,
                        timeRange: selectedTimeRange
                    )

                    // Main lift trends
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Main Lift Progress")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(compoundExercises.prefix(6)) { exercise in
                                    LiftTrendCard(
                                        exercise: exercise,
                                        sessions: filteredSessions,
                                        unitSystem: unitSystem
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Detailed exercise selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detailed Progress")
                            .font(.headline)
                            .padding(.horizontal)

                        Menu {
                            ForEach(compoundExercises) { exercise in
                                Button(exercise.name) {
                                    selectedExercise = exercise
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedExercise?.name ?? "Select Exercise")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        if let exercise = selectedExercise {
                            DetailedExerciseChart(
                                exercise: exercise,
                                sessions: filteredSessions,
                                unitSystem: unitSystem
                            )
                        }
                    }

                    // Weekly review button
                    Button {
                        showWeeklyReview = true
                    } label: {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Weekly Review")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .sheet(isPresented: $showWeeklyReview) {
                WeeklyReviewSheet(sessions: filteredSessions)
            }
        }
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"

    var id: String { rawValue }

    var cutoffDate: Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: Date())!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: Date())!
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: Date())!
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: Date())!
        }
    }
}

struct WeeklySummaryCard: View {
    let sessions: [WorkoutSession]

    private var thisWeekSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessions.filter { $0.date >= startOfWeek }
    }

    private var totalVolume: Double {
        thisWeekSessions.reduce(0) { $0 + $1.totalVolume }
    }

    private var totalDuration: Int {
        thisWeekSessions.compactMap { $0.actualDuration }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 16) {
                WeekStatBox(
                    title: "Workouts",
                    value: "\(thisWeekSessions.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: .blue
                )

                WeekStatBox(
                    title: "Volume",
                    value: formatVolume(totalVolume),
                    icon: "scalemass.fill",
                    color: .green
                )

                WeekStatBox(
                    title: "Time",
                    value: "\(totalDuration) min",
                    icon: "clock.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

struct WeekStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct VolumeChartCard: View {
    let sessions: [WorkoutSession]
    let timeRange: TimeRange

    private var volumeByDate: [(date: Date, volume: Double)] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }

        return grouped.map { date, daySessions in
            (date, daySessions.reduce(0) { $0 + $1.totalVolume })
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Volume")
                .font(.headline)

            if volumeByDate.isEmpty {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 150)
            } else {
                Chart(volumeByDate, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct LiftTrendCard: View {
    let exercise: Exercise
    let sessions: [WorkoutSession]
    let unitSystem: UnitSystem

    private var e1RMHistory: [(date: Date, e1RM: Double)] {
        let calendar = Calendar.current

        let relevantSets = sessions.flatMap { session in
            session.sets.filter {
                $0.exercise?.id == exercise.id &&
                $0.isCompleted &&
                $0.setType != .warmup
            }.map { (session.date, $0.e1RM) }
        }

        // Group by day and get max
        let grouped = Dictionary(grouping: relevantSets) { item in
            calendar.startOfDay(for: item.0)
        }

        return grouped.compactMap { date, sets in
            guard let maxE1RM = sets.map({ $0.1 }).max() else { return nil }
            return (date, maxE1RM)
        }.sorted { $0.date < $1.date }
    }

    private var currentE1RM: Double? {
        e1RMHistory.last?.e1RM
    }

    private var trend: Double? {
        guard e1RMHistory.count >= 2 else { return nil }
        let first = e1RMHistory.first!.e1RM
        let last = e1RMHistory.last!.e1RM
        return ((last - first) / first) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.caption.bold())
                .lineLimit(1)

            if let e1RM = currentE1RM {
                Text(unitSystem.formatWeight(e1RM))
                    .font(.title3.bold())
            } else {
                Text("-")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }

            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(trend), specifier: "%.1f")%")
                }
                .font(.caption)
                .foregroundStyle(trend >= 0 ? .green : .red)
            } else {
                Text("No trend")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailedExerciseChart: View {
    let exercise: Exercise
    let sessions: [WorkoutSession]
    let unitSystem: UnitSystem

    private var e1RMHistory: [(date: Date, e1RM: Double)] {
        let calendar = Calendar.current

        let relevantSets = sessions.flatMap { session in
            session.sets.filter {
                $0.exercise?.id == exercise.id &&
                $0.isCompleted &&
                $0.setType != .warmup
            }.map { (session.date, $0.e1RM) }
        }

        let grouped = Dictionary(grouping: relevantSets) { item in
            calendar.startOfDay(for: item.0)
        }

        return grouped.compactMap { date, sets in
            guard let maxE1RM = sets.map({ $0.1 }).max() else { return nil }
            return (date, maxE1RM)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if e1RMHistory.isEmpty {
                Text("No data for \(exercise.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 200)
            } else {
                Chart(e1RMHistory, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("e1RM", unitSystem.convert(kg: item.e1RM))
                    )
                    .foregroundStyle(Color.blue.gradient)

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("e1RM", unitSystem.convert(kg: item.e1RM))
                    )
                    .foregroundStyle(Color.blue.opacity(0.1).gradient)

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("e1RM", unitSystem.convert(kg: item.e1RM))
                    )
                    .foregroundStyle(Color.blue)
                }
                .frame(height: 200)
                .chartYAxisLabel("e1RM (\(unitSystem.weightUnit))")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct WeeklyReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sessions: [WorkoutSession]

    @State private var review: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Analyzing your week...")
                            .padding(.top, 50)
                    } else if let review = review {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Weekly Review", systemImage: "brain.head.profile")
                                .font(.headline)

                            Text(review)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    } else {
                        Text("Unable to generate review")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Weekly Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            generateReview()
        }
    }

    private func generateReview() {
        Task {
            // Simple offline review for now
            await MainActor.run {
                let workoutCount = sessions.count
                let totalVolume = sessions.reduce(0) { $0 + $1.totalVolume }

                var reviewText = "You completed \(workoutCount) workouts this period. "

                if workoutCount >= 4 {
                    reviewText += "Great consistency! "
                } else if workoutCount >= 2 {
                    reviewText += "Solid effort. Try to add one more session next week. "
                } else {
                    reviewText += "Consider increasing training frequency for better results. "
                }

                if totalVolume > 10000 {
                    reviewText += "Your training volume is high. Monitor recovery and consider a deload if fatigue builds up."
                } else if totalVolume > 5000 {
                    reviewText += "Good training volume. Keep progressing gradually."
                } else {
                    reviewText += "Training volume is moderate. You may have room to add sets if recovery allows."
                }

                self.review = reviewText
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ProgressView_Custom()
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, Exercise.self], inMemory: true)
}
