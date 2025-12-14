import Foundation

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric = "Metric (kg)"
    case imperial = "Imperial (lbs)"

    var id: String { rawValue }

    var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }

    var smallIncrement: Double {
        switch self {
        case .metric: return 2.5
        case .imperial: return 5.0
        }
    }

    var microIncrement: Double {
        switch self {
        case .metric: return 1.0
        case .imperial: return 2.5
        }
    }

    func convert(kg: Double) -> Double {
        switch self {
        case .metric: return kg
        case .imperial: return kg * 2.20462
        }
    }

    func toKg(_ value: Double) -> Double {
        switch self {
        case .metric: return value
        case .imperial: return value / 2.20462
        }
    }

    func formatWeight(_ kg: Double) -> String {
        let value = convert(kg: kg)
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value)) \(weightUnit)"
        }
        return String(format: "%.1f \(weightUnit)", value)
    }
}
