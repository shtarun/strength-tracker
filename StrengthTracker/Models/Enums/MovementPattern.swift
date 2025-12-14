import Foundation

enum MovementPattern: String, Codable, CaseIterable, Identifiable {
    case horizontalPush = "Horizontal Push"
    case verticalPush = "Vertical Push"
    case horizontalPull = "Horizontal Pull"
    case verticalPull = "Vertical Pull"
    case squat = "Squat"
    case hinge = "Hinge"
    case lunge = "Lunge"
    case carry = "Carry"
    case isolation = "Isolation"

    var id: String { rawValue }

    var primaryMuscleGroups: [Muscle] {
        switch self {
        case .horizontalPush: return [.chest, .frontDelt, .triceps]
        case .verticalPush: return [.frontDelt, .sideDelt, .triceps]
        case .horizontalPull: return [.upperBack, .lats, .rearDelt, .biceps]
        case .verticalPull: return [.lats, .upperBack, .biceps]
        case .squat: return [.quads, .glutes]
        case .hinge: return [.hamstrings, .glutes, .lowerBack]
        case .lunge: return [.quads, .glutes, .hamstrings]
        case .carry: return [.core, .traps, .forearms]
        case .isolation: return []
        }
    }
}
