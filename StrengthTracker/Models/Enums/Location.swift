import Foundation

enum Location: String, Codable, CaseIterable, Identifiable {
    case gym = "Gym"
    case home = "Home"
    case mixed = "Mixed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gym: return "building.2.fill"
        case .home: return "house.fill"
        case .mixed: return "arrow.triangle.2.circlepath"
        }
    }

    var description: String {
        switch self {
        case .gym:
            return "Full gym access with all equipment"
        case .home:
            return "Home gym with limited equipment"
        case .mixed:
            return "Some days at gym, some at home"
        }
    }
}
