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
    @State private var selectedTab: ProgressTab = .overview

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
            VStack(spacing: 0) {
                // Tab selector
                ProgressTabPicker(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
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
                        
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .lifts:
                            liftsContent
                        case .calendar:
                            calendarContent
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showWeeklyReview) {
                WeeklyReviewSheet(
                    sessions: filteredSessions,
                    provider: profile?.preferredLLMProvider ?? .offline
                )
            }
        }
    }
    
    // MARK: - Overview Tab
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Weekly summary with comparison
            WeeklySummaryCard(sessions: sessions, allSessions: sessions)
            
            // Recent PRs
            RecentPRsCard(sessions: filteredSessions, unitSystem: unitSystem)

            // Volume chart
            VolumeChartCard(
                sessions: filteredSessions,
                timeRange: selectedTimeRange
            )
            
            // Muscle group breakdown
            MuscleGroupBreakdownCard(sessions: filteredSessions)

            // Weekly review button
            Button {
                showWeeklyReview = true
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("AI Weekly Review")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }
    
    // All completed sessions for full history view
    private var allCompletedSessions: [WorkoutSession] {
        sessions.filter { $0.isCompleted }
    }
    
    // MARK: - Lifts Tab
    private var liftsContent: some View {
        VStack(spacing: 20) {
            // Main lift trends (uses filtered time range)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Main Lifts")
                        .font(.headline)
                    Spacer()
                    Text("(\(selectedTimeRange.rawValue))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(compoundExercises.prefix(6)) { exercise in
                            LiftTrendCard(
                                exercise: exercise,
                                sessions: filteredSessions,
                                unitSystem: unitSystem,
                                isSelected: selectedExercise?.id == exercise.id,
                                onTap: { selectedExercise = exercise }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Detailed exercise chart (uses ALL sessions for full history)
            if let exercise = selectedExercise {
                DetailedExerciseChart(
                    exercise: exercise,
                    sessions: allCompletedSessions,  // Full history!
                    unitSystem: unitSystem
                )
                
                // Exercise stats (also full history)
                ExerciseStatsCard(
                    exercise: exercise,
                    sessions: allCompletedSessions,
                    unitSystem: unitSystem
                )
            } else {
                // Prompt to select
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Tap a lift above to see detailed progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Calendar Tab
    private var calendarContent: some View {
        VStack(spacing: 20) {
            TrainingCalendarView(sessions: sessions)
            
            // Streak info
            StreakCard(sessions: sessions)
        }
    }
}

// MARK: - Progress Tab Enum & Picker

enum ProgressTab: String, CaseIterable {
    case overview = "Overview"
    case lifts = "Lifts"
    case calendar = "Calendar"
}

struct ProgressTabPicker: View {
    @Binding var selectedTab: ProgressTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProgressTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: iconFor(tab))
                            .font(.title3)
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ? Color.blue.opacity(0.15) : Color.clear)
                    .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func iconFor(_ tab: ProgressTab) -> String {
        switch tab {
        case .overview: return "chart.bar.fill"
        case .lifts: return "dumbbell.fill"
        case .calendar: return "calendar"
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
    let allSessions: [WorkoutSession]

    private var thisWeekSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessions.filter { $0.date >= startOfWeek }
    }
    
    private var lastWeekSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
        return allSessions.filter { $0.date >= startOfLastWeek && $0.date < startOfThisWeek && $0.isCompleted }
    }

    private var totalVolume: Double {
        thisWeekSessions.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var lastWeekVolume: Double {
        lastWeekSessions.reduce(0) { $0 + $1.totalVolume }
    }

    private var totalDuration: Int {
        thisWeekSessions.compactMap { $0.actualDuration }.reduce(0, +)
    }
    
    private var volumeChange: Double? {
        guard lastWeekVolume > 0 else { return nil }
        return ((totalVolume - lastWeekVolume) / lastWeekVolume) * 100
    }
    
    private var workoutChange: Int {
        thisWeekSessions.count - lastWeekSessions.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                if let change = volumeChange {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(change), specifier: "%.0f")% volume")
                    }
                    .font(.caption)
                    .foregroundStyle(change >= 0 ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(change >= 0 ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                WeekStatBox(
                    title: "Workouts",
                    value: "\(thisWeekSessions.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: .blue,
                    change: workoutChange != 0 ? workoutChange : nil
                )

                WeekStatBox(
                    title: "Volume",
                    value: formatVolume(totalVolume),
                    icon: "scalemass.fill",
                    color: .green,
                    change: nil
                )

                WeekStatBox(
                    title: "Time",
                    value: "\(totalDuration) min",
                    icon: "clock.fill",
                    color: .orange,
                    change: nil
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
    var change: Int? = nil

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold())

            HStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let change = change {
                    Text(change > 0 ? "+\(change)" : "\(change)")
                        .font(.caption2)
                        .foregroundStyle(change >= 0 ? .green : .red)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recent PRs Card

struct RecentPRsCard: View {
    let sessions: [WorkoutSession]
    let unitSystem: UnitSystem
    
    private var recentPRs: [(exercise: String, weight: Double, reps: Int, date: Date)] {
        var prs: [(exercise: String, weight: Double, reps: Int, date: Date)] = []
        var bestE1RMs: [String: Double] = [:]
        
        // Sort sessions by date (oldest first) to track progression
        let sortedSessions = sessions.sorted { $0.date < $1.date }
        
        for session in sortedSessions {
            for set in session.sets where set.isCompleted && set.setType != .warmup {
                guard let exerciseName = set.exercise?.name else { continue }
                let e1RM = set.e1RM
                
                if let best = bestE1RMs[exerciseName] {
                    if e1RM > best {
                        bestE1RMs[exerciseName] = e1RM
                        prs.append((exerciseName, set.weight, set.reps, session.date))
                    }
                } else {
                    bestE1RMs[exerciseName] = e1RM
                }
            }
        }
        
        // Return last 5 PRs, most recent first
        return Array(prs.suffix(5).reversed())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent PRs", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("🎉")
                    .font(.title2)
            }
            
            if recentPRs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Keep training to set new PRs!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(recentPRs.indices, id: \.self) { index in
                    let pr = recentPRs[index]
                    HStack {
                        Circle()
                            .fill(Color.yellow.gradient)
                            .frame(width: 8, height: 8)
                        
                        Text(pr.exercise)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(unitSystem.formatWeight(pr.weight)) × \(pr.reps)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        
                        Text(pr.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if index < recentPRs.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Muscle Group Breakdown

struct MuscleGroupBreakdownCard: View {
    let sessions: [WorkoutSession]
    
    private var muscleVolume: [(muscle: String, sets: Int)] {
        var volumeByMuscle: [Muscle: Int] = [:]
        
        for session in sessions {
            for set in session.sets where set.isCompleted && set.setType != .warmup {
                guard let exercise = set.exercise else { continue }
                
                for muscle in exercise.primaryMuscles {
                    volumeByMuscle[muscle, default: 0] += 1
                }
                for muscle in exercise.secondaryMuscles {
                    volumeByMuscle[muscle, default: 0] += 1
                }
            }
        }
        
        return volumeByMuscle
            .map { (muscle: $0.key.rawValue.capitalized, sets: $0.value) }
            .sorted { $0.sets > $1.sets }
            .prefix(6)
            .map { $0 }
    }
    
    private var maxSets: Int {
        muscleVolume.first?.sets ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Group Focus")
                .font(.headline)
            
            if muscleVolume.isEmpty {
                Text("No workout data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(muscleVolume.indices, id: \.self) { index in
                    let item = muscleVolume[index]
                    HStack {
                        Text(item.muscle)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.gradient)
                                .frame(width: geo.size.width * CGFloat(item.sets) / CGFloat(maxSets))
                        }
                        .frame(height: 20)
                        
                        Text("\(item.sets) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct VolumeChartCard: View {
    let sessions: [WorkoutSession]
    let timeRange: TimeRange

    private var volumeData: [(date: Date, volume: Double, label: String)] {
        let calendar = Calendar.current
        
        // Group by week for longer time ranges, by day for week view
        if timeRange == .week {
            // Daily view for week
            let grouped = Dictionary(grouping: sessions) { session in
                calendar.startOfDay(for: session.date)
            }
            return grouped.map { date, daySessions in
                let volume = daySessions.reduce(0) { $0 + $1.totalVolume }
                let label = date.formatted(.dateTime.weekday(.abbreviated))
                return (date, volume, label)
            }.sorted { $0.date < $1.date }
        } else {
            // Weekly aggregation for longer periods
            let grouped = Dictionary(grouping: sessions) { session in
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.date)
                return calendar.date(from: components)!
            }
            return grouped.map { weekStart, weekSessions in
                let volume = weekSessions.reduce(0) { $0 + $1.totalVolume }
                let label = weekStart.formatted(.dateTime.month(.abbreviated).day())
                return (weekStart, volume, label)
            }.sorted { $0.date < $1.date }
        }
    }
    
    private var totalVolume: Double {
        sessions.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var averagePerSession: Double {
        sessions.isEmpty ? 0 : totalVolume / Double(sessions.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Training Volume")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatVolume(totalVolume))
                        .font(.subheadline.bold())
                    Text("total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if volumeData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No workouts in this period")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 150)
            } else {
                Chart(volumeData, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: timeRange == .week ? .day : .weekOfYear),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .annotation(position: .top, alignment: .center) {
                        if item.volume > 0 {
                            Text(formatVolume(item.volume))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(volumeData.count, 7))) { value in
                        AxisGridLine()
                        AxisValueLabel(format: timeRange == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatVolume(v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                
                // Summary stats
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sessions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(sessions.count)")
                            .font(.subheadline.bold())
                    }
                    Divider().frame(height: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg/Session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatVolume(averagePerSession))
                            .font(.subheadline.bold())
                    }
                }
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

struct LiftTrendCard: View {
    let exercise: Exercise
    let sessions: [WorkoutSession]
    let unitSystem: UnitSystem
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    private var e1RMHistory: [(date: Date, e1RM: Double)] {
        let calendar = Calendar.current
        let exerciseName = exercise.name

        // Get all sets for this exercise by NAME (more reliable than ID)
        let relevantSets = sessions.flatMap { session in
            session.sets.filter {
                $0.exercise?.name == exerciseName &&
                $0.isCompleted &&
                $0.setType != .warmup &&
                $0.weight > 0 &&
                $0.reps > 0
            }.map { (session.date, $0.e1RM) }
        }

        // Group by day and get max e1RM for each day
        let grouped = Dictionary(grouping: relevantSets) { item in
            calendar.startOfDay(for: item.0)
        }

        return grouped.compactMap { date, sets in
            guard let maxE1RM = sets.map({ $0.1 }).max(), maxE1RM > 0 else { return nil }
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
        guard first > 0 else { return nil }
        return ((last - first) / first) * 100
    }
    
    private var sessionCount: Int {
        e1RMHistory.count
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.caption.bold())
                    .lineLimit(1)

                if let e1RM = currentE1RM {
                    Text(unitSystem.formatWeight(e1RM))
                        .font(.title3.bold())
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(trend), specifier: "%.1f")%")
                    }
                    .font(.caption)
                    .foregroundStyle(trend >= 0 ? .green : .red)
                } else if sessionCount > 0 {
                    Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct DetailedExerciseChart: View {
    let exercise: Exercise
    let sessions: [WorkoutSession]
    let unitSystem: UnitSystem
    
    @State private var selectedPoint: (date: Date, e1RM: Double)?

    private var e1RMHistory: [(date: Date, e1RM: Double, weight: Double, reps: Int)] {
        let calendar = Calendar.current
        let exerciseName = exercise.name

        // Get all completed working sets for this exercise by NAME
        let relevantSets = sessions.flatMap { session in
            session.sets.compactMap { set -> (Date, Double, Double, Int)? in
                guard set.exercise?.name == exerciseName,
                      set.isCompleted,
                      set.setType != .warmup,
                      set.weight > 0,
                      set.reps > 0 else { return nil }
                return (session.date, set.e1RM, set.weight, set.reps)
            }
        }

        // Group by day and get the best set (max e1RM) for each day
        let grouped = Dictionary(grouping: relevantSets) { item in
            calendar.startOfDay(for: item.0)
        }

        return grouped.compactMap { date, sets in
            guard let best = sets.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
            return (date, best.1, best.2, best.3)
        }.sorted { $0.date < $1.date }
    }
    
    private var prSet: (date: Date, e1RM: Double, weight: Double, reps: Int)? {
        e1RMHistory.max { $0.e1RM < $1.e1RM }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                    if let pr = prSet {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("PR: \(unitSystem.formatWeight(pr.weight)) × \(pr.reps)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                if let point = selectedPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("e1RM: \(unitSystem.formatWeight(point.e1RM))")
                            .font(.subheadline.bold())
                        Text(point.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let last = e1RMHistory.last {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Current: \(unitSystem.formatWeight(last.e1RM))")
                            .font(.subheadline.bold())
                        Text("\(e1RMHistory.count) sessions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if e1RMHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No workout history for \(exercise.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Complete a workout with this exercise to see your progress")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 200)
            } else {
                Chart(e1RMHistory, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("e1RM", unitSystem.convert(kg: item.e1RM))
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("e1RM", unitSystem.convert(kg: item.e1RM))
                    )
                    .foregroundStyle(Color.blue.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("e1RM", unitSystem.convert(kg: item.e1RM))
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(selectedPoint?.date == item.date ? 100 : 30)
                }
                .frame(height: 200)
                .chartYAxisLabel("e1RM (\(unitSystem.weightUnit))")
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame = proxy.plotFrame else { return }
                                        let x = value.location.x - geo[plotFrame].origin.x
                                        if let date: Date = proxy.value(atX: x) {
                                            // Find closest point
                                            if let closest = e1RMHistory.min(by: {
                                                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                            }) {
                                                selectedPoint = (closest.date, closest.e1RM)
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedPoint = nil
                                    }
                            )
                    }
                }
                
                // Session history list
                if e1RMHistory.count > 1 {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Sessions")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        ForEach(e1RMHistory.suffix(5).reversed(), id: \.date) { item in
                            HStack {
                                Text(item.date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                Text("\(unitSystem.formatWeight(item.weight)) × \(item.reps)")
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("e1RM: \(unitSystem.formatWeight(item.e1RM))")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Exercise Stats Card

struct ExerciseStatsCard: View {
    let exercise: Exercise
    let sessions: [WorkoutSession]
    let unitSystem: UnitSystem
    
    private var exerciseName: String { exercise.name }
    
    private var relevantSets: [WorkoutSet] {
        sessions.flatMap { session in
            session.sets.filter {
                $0.exercise?.name == exerciseName &&
                $0.isCompleted &&
                $0.setType != .warmup &&
                $0.weight > 0 &&
                $0.reps > 0
            }
        }
    }
    
    private var bestE1RM: Double {
        relevantSets.map { $0.e1RM }.max() ?? 0
    }
    
    private var totalSets: Int {
        relevantSets.count
    }
    
    private var averageRPE: Double? {
        let rpes = relevantSets.compactMap { $0.rpe }
        guard !rpes.isEmpty else { return nil }
        return rpes.reduce(0, +) / Double(rpes.count)
    }
    
    private var sessionsCount: Int {
        sessions.filter { session in
            session.sets.contains { $0.exercise?.name == exerciseName && $0.isCompleted }
        }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                StatPill(
                    title: "Best e1RM",
                    value: bestE1RM > 0 ? unitSystem.formatWeight(bestE1RM) : "-",
                    color: .yellow
                )
                
                StatPill(
                    title: "Sessions",
                    value: "\(sessionsCount)",
                    color: .blue
                )
                
                StatPill(
                    title: "Total Sets",
                    value: "\(totalSets)",
                    color: .green
                )
                
                if let rpe = averageRPE {
                    StatPill(
                        title: "Avg RPE",
                        value: String(format: "%.1f", rpe),
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Training Calendar View

struct TrainingCalendarView: View {
    let sessions: [WorkoutSession]
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    @State private var currentMonth = Date()
    
    private var monthDays: [Date?] {
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstDay = interval.start
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end)!
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        
        var day = firstDay
        while day <= lastDay {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        
        return days
    }
    
    private func sessionsOn(_ date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return sessions.filter { $0.date >= dayStart && $0.date < dayEnd && $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                
                Spacer()
                
                Button {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        let count = sessionsOn(date)
                        let isToday = calendar.isDateInToday(date)
                        
                        VStack(spacing: 2) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.caption)
                                .fontWeight(isToday ? .bold : .regular)
                            
                            Circle()
                                .fill(colorForSessions(count))
                                .frame(width: 6, height: 6)
                        }
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(isToday ? Color.blue.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(Color.clear).frame(width: 8, height: 8)
                    Text("Rest")
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("Trained")
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("2+ workouts")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func colorForSessions(_ count: Int) -> Color {
        switch count {
        case 0: return Color.clear
        case 1: return Color.green
        default: return Color.blue
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let sessions: [WorkoutSession]
    
    private var currentStreak: Int {
        var streak = 0
        var checkDate = Date()
        let calendar = Calendar.current

        for _ in 0..<365 {
            let dayStart = calendar.startOfDay(for: checkDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let hasWorkout = sessions.contains { session in
                session.date >= dayStart && session.date < dayEnd && session.isCompleted
            }

            if hasWorkout {
                streak += 1
            } else if streak > 0 {
                break
            }

            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        return streak
    }
    
    private var longestStreak: Int {
        var longest = 0
        var current = 0
        var lastWorkoutDate: Date?
        let calendar = Calendar.current
        
        let sortedSessions = sessions.filter { $0.isCompleted }.sorted { $0.date < $1.date }
        
        for session in sortedSessions {
            let sessionDay = calendar.startOfDay(for: session.date)
            
            if let last = lastWorkoutDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: sessionDay).day ?? 0
                if daysBetween <= 1 {
                    current += 1
                } else {
                    longest = max(longest, current)
                    current = 1
                }
            } else {
                current = 1
            }
            
            lastWorkoutDate = sessionDay
        }
        
        return max(longest, current)
    }
    
    private var thisMonthCount: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return sessions.filter { $0.date >= startOfMonth && $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(currentStreak)")
                            .font(.title.bold())
                    }
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("\(longestStreak)")
                            .font(.title.bold())
                    }
                    Text("Longest Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                        Text("\(thisMonthCount)")
                            .font(.title.bold())
                    }
                    Text("This Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
    let provider: LLMProviderType

    @State private var review: WeeklyReviewResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Analyzing your week...")
                            .padding(.top, 50)
                    } else if let review = review {
                        VStack(alignment: .leading, spacing: 16) {
                            // Consistency Score
                            HStack {
                                Label("Consistency Score", systemImage: "chart.bar.fill")
                                    .font(.headline)
                                Spacer()
                                Text("\(review.consistencyScore)/10")
                                    .font(.title2.bold())
                                    .foregroundStyle(scoreColor(review.consistencyScore))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Summary
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Summary", systemImage: "brain.head.profile")
                                    .font(.headline)

                                Text(review.summary)
                                    .font(.body)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Highlights
                            if !review.highlights.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Highlights", systemImage: "star.fill")
                                        .font(.headline)
                                        .foregroundStyle(.yellow)

                                    ForEach(review.highlights, id: \.self) { highlight in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text(highlight)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Areas to Improve
                            if !review.areasToImprove.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Focus Areas", systemImage: "target")
                                        .font(.headline)
                                        .foregroundStyle(.orange)

                                    ForEach(review.areasToImprove, id: \.self) { area in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundStyle(.orange)
                                            Text(area)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Recommendation
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Next Week", systemImage: "arrow.forward.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.blue)

                                Text(review.recommendation)
                                    .font(.body)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text(error)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 50)
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

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 8...10: return .green
        case 5...7: return .yellow
        default: return .orange
        }
    }

    private func generateReview() {
        Task {
            // Build context from sessions
            let context = buildContext()

            do {
                let result = try await LLMService.shared.generateWeeklyReview(
                    context: context,
                    provider: provider
                )
                await MainActor.run {
                    self.review = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Unable to generate review: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func buildContext() -> WeeklyReviewContext {
        let workoutCount = sessions.count
        let totalVolume = sessions.reduce(0) { $0 + $1.totalVolume }
        let averageDuration = sessions.isEmpty ? 0 : sessions.reduce(0) { $0 + ($1.actualDuration ?? 0) } / sessions.count

        // Build exercise highlights - group sets by exercise
        var exerciseData: [String: (sessions: Int, bestE1RM: Double, volume: Double)] = [:]

        for session in sessions {
            // Group sets by exercise
            var sessionExercises: [String: [WorkoutSet]] = [:]
            for set in session.sets where set.isCompleted {
                guard let exercise = set.exercise else { continue }
                sessionExercises[exercise.name, default: []].append(set)
            }

            // Process each exercise in this session
            for (exerciseName, sets) in sessionExercises {
                let currentData = exerciseData[exerciseName] ?? (sessions: 0, bestE1RM: 0, volume: 0)
                let sessionE1RM = sets.map { E1RMCalculator.calculate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
                let sessionVolume = sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }

                exerciseData[exerciseName] = (
                    sessions: currentData.sessions + 1,
                    bestE1RM: max(currentData.bestE1RM, sessionE1RM),
                    volume: currentData.volume + sessionVolume
                )
            }
        }

        let highlights = exerciseData.map { name, data in
            WeeklyExerciseHighlight(
                exerciseName: name,
                sessions: data.sessions,
                bestE1RM: data.bestE1RM,
                previousBestE1RM: nil, // Would need historical data
                totalVolume: data.volume
            )
        }

        return WeeklyReviewContext(
            workoutCount: workoutCount,
            totalVolume: totalVolume,
            averageDuration: averageDuration,
            exerciseHighlights: highlights,
            userGoal: "strength" // Could be fetched from UserProfile
        )
    }
}

#Preview {
    ProgressView_Custom()
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, Exercise.self], inMemory: true)
}
