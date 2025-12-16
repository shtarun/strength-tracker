import Foundation

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case kettlebell = "Kettlebell"
    case cable = "Cable"
    case machine = "Machine"
    case pullUpBar = "Pull-up Bar"
    case bands = "Resistance Bands"
    case bodyweight = "Bodyweight"
    case rack = "Squat Rack"
    case bench = "Bench"
    case cardioMachine = "Cardio Machine"
    case foamRoller = "Foam Roller"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .kettlebell: return "figure.highintensity.intervaltraining"
        case .cable: return "cable.connector"
        case .machine: return "gearshape.fill"
        case .pullUpBar: return "figure.climbing"
        case .bands: return "lasso"
        case .bodyweight: return "figure.stand"
        case .rack: return "square.stack.3d.up.fill"
        case .bench: return "bed.double.fill"
        case .cardioMachine: return "figure.run"
        case .foamRoller: return "figure.flexibility"
        }
    }

    var requiresGym: Bool {
        switch self {
        case .cable, .machine, .cardioMachine:
            return true
        default:
            return false
        }
    }
}
