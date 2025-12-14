import Foundation

enum ProgressionType: String, Codable, CaseIterable, Identifiable {
    case topSetBackoff = "Top Set + Backoffs"
    case doubleProgression = "Double Progression"
    case straightSets = "Straight Sets"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .topSetBackoff:
            return "One heavy top set, then lighter backoff sets"
        case .doubleProgression:
            return "Keep weight until hitting top of rep range, then increase"
        case .straightSets:
            return "Same weight and reps for all sets"
        }
    }
}
