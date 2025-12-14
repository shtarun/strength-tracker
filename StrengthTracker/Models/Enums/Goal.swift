import Foundation

enum Goal: String, Codable, CaseIterable, Identifiable {
    case strength = "Strength"
    case hypertrophy = "Hypertrophy"
    case both = "Both"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .strength:
            return "Focus on lifting heavier weights with lower reps (1-6 reps)"
        case .hypertrophy:
            return "Focus on muscle growth with moderate reps (8-12 reps)"
        case .both:
            return "Balanced approach combining strength and muscle building"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .hypertrophy: return "figure.arms.open"
        case .both: return "figure.mixed.cardio"
        }
    }
}
