import Foundation

enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case ok = "OK"
    case high = "High"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .ok: return "battery.50"
        case .high: return "battery.100"
        }
    }

    var color: String {
        switch self {
        case .low: return "red"
        case .ok: return "yellow"
        case .high: return "green"
        }
    }
}

enum SorenessLevel: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case mild = "Mild"
    case high = "High"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "checkmark.circle.fill"
        case .mild: return "exclamationmark.circle.fill"
        case .high: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .none: return "green"
        case .mild: return "yellow"
        case .high: return "red"
        }
    }
}

enum PainSeverity: String, Codable, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var id: String { rawValue }
}

struct Readiness: Codable, Equatable {
    var energy: EnergyLevel
    var soreness: SorenessLevel
    var timeAvailable: Int // minutes: 30, 45, 60, 75

    static let `default` = Readiness(energy: .ok, soreness: .none, timeAvailable: 60)

    var isDefault: Bool {
        self == Readiness.default
    }

    var shouldReduceIntensity: Bool {
        energy == .low || soreness == .high
    }

    var shouldIncreaseIntensity: Bool {
        energy == .high && soreness == .none
    }
}
