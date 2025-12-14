import Foundation

enum Split: String, Codable, CaseIterable, Identifiable {
    case upperLower = "Upper/Lower"
    case ppl = "Push/Pull/Legs"
    case fullBody = "Full Body"
    case custom = "Custom"

    var id: String { rawValue }

    var daysPerWeek: Int {
        switch self {
        case .upperLower: return 4
        case .ppl: return 6
        case .fullBody: return 3
        case .custom: return 0
        }
    }

    var description: String {
        switch self {
        case .upperLower:
            return "4 days: Upper A, Lower A, Upper B, Lower B"
        case .ppl:
            return "6 days: Push, Pull, Legs repeated twice"
        case .fullBody:
            return "3 days: Full body workouts with rest days between"
        case .custom:
            return "Create your own split"
        }
    }

    var dayNames: [String] {
        switch self {
        case .upperLower:
            return ["Upper A", "Lower A", "Upper B", "Lower B"]
        case .ppl:
            return ["Push", "Pull", "Legs", "Push", "Pull", "Legs"]
        case .fullBody:
            return ["Full Body A", "Full Body B", "Full Body C"]
        case .custom:
            return []
        }
    }
}
