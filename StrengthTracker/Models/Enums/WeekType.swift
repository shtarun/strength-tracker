import Foundation
import SwiftUI

/// Represents the type of training week within a workout plan
enum WeekType: String, Codable, CaseIterable, Identifiable {
    case regular = "Regular"
    case deload = "Deload"
    case peak = "Peak"
    case test = "Test/Max"
    
    var id: String { rawValue }
    
    /// Intensity modifier applied to working weights
    /// 1.0 = 100% of normal, 0.6 = 60% (deload), 1.05 = 105% (peak)
    var intensityModifier: Double {
        switch self {
        case .regular: return 1.0
        case .deload: return 0.6
        case .peak: return 1.05
        case .test: return 1.0  // Test week uses actual maxes
        }
    }
    
    /// Volume modifier applied to number of sets
    /// 1.0 = 100% of normal sets, 0.5 = 50% (deload)
    var volumeModifier: Double {
        switch self {
        case .regular: return 1.0
        case .deload: return 0.5
        case .peak: return 0.75  // Reduced volume, higher intensity
        case .test: return 0.3   // Minimal volume for testing
        }
    }
    
    /// RPE cap for this week type
    var rpeCap: Double {
        switch self {
        case .regular: return 8.5
        case .deload: return 6.5
        case .peak: return 9.0
        case .test: return 10.0
        }
    }
    
    var icon: String {
        switch self {
        case .regular: return "figure.strengthtraining.traditional"
        case .deload: return "arrow.down.circle.fill"
        case .peak: return "arrow.up.circle.fill"
        case .test: return "trophy.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .regular: return .blue
        case .deload: return .orange
        case .peak: return .purple
        case .test: return .yellow
        }
    }
    
    var description: String {
        switch self {
        case .regular:
            return "Normal training intensity and volume"
        case .deload:
            return "Reduced intensity (60%) and volume (50%) for recovery"
        case .peak:
            return "Higher intensity (105%), reduced volume for strength expression"
        case .test:
            return "Test your maxes with minimal fatigue buildup"
        }
    }
    
    var coachingNotes: String {
        switch self {
        case .regular:
            return "Focus on progressive overload and proper form."
        case .deload:
            return "Take it easy this week. Focus on technique and mobility. You'll come back stronger!"
        case .peak:
            return "Time to express your strength. Push the weights but keep reps lower."
        case .test:
            return "Test your 1RM or rep maxes. Warm up thoroughly and rest fully between attempts."
        }
    }
}
