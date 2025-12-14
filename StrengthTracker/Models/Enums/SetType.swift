import Foundation

enum SetType: String, Codable, CaseIterable, Identifiable {
    case warmup = "Warmup"
    case topSet = "Top Set"
    case backoff = "Backoff"
    case working = "Working"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .warmup: return "W"
        case .topSet: return "T"
        case .backoff: return "B"
        case .working: return ""
        }
    }

    var color: String {
        switch self {
        case .warmup: return "gray"
        case .topSet: return "orange"
        case .backoff: return "blue"
        case .working: return "green"
        }
    }
}
