import SwiftUI

struct ReadinessCheckSheet: View {
    let template: WorkoutTemplate
    let onStart: (Readiness) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var energy: EnergyLevel = .ok
    @State private var soreness: SorenessLevel = .none
    @State private var timeAvailable: Int = 60

    private let timeOptions = [30, 45, 60, 75]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Quick Check-in")
                        .font(.title.bold())

                    Text("3 taps and you're ready")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                // Energy
                VStack(alignment: .leading, spacing: 12) {
                    Label("How's your energy?", systemImage: "bolt.fill")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(EnergyLevel.allCases) { level in
                            ReadinessButton(
                                title: level.rawValue,
                                icon: level.icon,
                                color: colorFor(level),
                                isSelected: energy == level
                            ) {
                                energy = level
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Soreness
                VStack(alignment: .leading, spacing: 12) {
                    Label("Any soreness?", systemImage: "figure.walk")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(SorenessLevel.allCases) { level in
                            ReadinessButton(
                                title: level.rawValue,
                                icon: level.icon,
                                color: colorFor(level),
                                isSelected: soreness == level
                            ) {
                                soreness = level
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Time
                VStack(alignment: .leading, spacing: 12) {
                    Label("Time available", systemImage: "clock.fill")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(timeOptions, id: \.self) { time in
                            TimeButton(
                                minutes: time,
                                isSelected: timeAvailable == time
                            ) {
                                timeAvailable = time
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Adjustment preview
                if energy == .low || soreness == .high {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)

                        Text("Intensity will be reduced based on your readiness")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }

                // Start button
                Button {
                    let readiness = Readiness(
                        energy: energy,
                        soreness: soreness,
                        timeAvailable: timeAvailable
                    )
                    onStart(readiness)
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Let's Go")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func colorFor(_ level: EnergyLevel) -> Color {
        switch level {
        case .low: return .red
        case .ok: return .yellow
        case .high: return .green
        }
    }

    private func colorFor(_ level: SorenessLevel) -> Color {
        switch level {
        case .none: return .green
        case .mild: return .yellow
        case .high: return .red
        }
    }
}

struct ReadinessButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

struct TimeButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.title2.bold())

                Text("min")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? .blue : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReadinessCheckSheet(
        template: WorkoutTemplate(name: "Upper A", dayNumber: 1),
        onStart: { _ in }
    )
}
