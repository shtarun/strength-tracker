import Foundation

enum Muscle: String, Codable, CaseIterable, Identifiable {
    // Chest
    case chest = "Chest"

    // Back
    case lats = "Lats"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"

    // Shoulders
    case frontDelt = "Front Delts"
    case sideDelt = "Side Delts"
    case rearDelt = "Rear Delts"

    // Arms
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"

    // Legs
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"

    // Core
    case core = "Core"
    case traps = "Traps"

    var id: String { rawValue }

    var bodyPart: BodyPart {
        switch self {
        case .chest: return .chest
        case .lats, .upperBack, .lowerBack: return .back
        case .frontDelt, .sideDelt, .rearDelt: return .shoulders
        case .biceps, .triceps, .forearms: return .arms
        case .quads, .hamstrings, .glutes, .calves: return .legs
        case .core, .traps: return .core
        }
    }
}

enum BodyPart: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"

    var id: String { rawValue }
}
