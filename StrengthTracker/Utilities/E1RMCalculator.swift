import Foundation

enum E1RMCalculator {
    /// Calculate estimated 1 rep max using Epley formula
    /// e1RM = weight × (1 + reps/30)
    static func calculate(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// Calculate estimated 1 rep max using Brzycki formula
    /// e1RM = weight × (36 / (37 - reps))
    static func calculateBrzycki(weight: Double, reps: Int) -> Double {
        guard reps > 0 && reps < 37 else { return weight }
        if reps == 1 { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }

    /// Calculate weight needed for target reps at given e1RM
    static func weightForReps(e1RM: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return e1RM }
        return e1RM / (1 + Double(reps) / 30.0)
    }

    /// Calculate percentage of 1RM
    static func percentageOf1RM(weight: Double, reps: Int) -> Double {
        let e1RM = calculate(weight: weight, reps: reps)
        guard e1RM > 0 else { return 0 }
        return weight / e1RM * 100
    }

    /// Get rep ranges for different percentages
    static func repsAtPercentage(_ percentage: Double) -> Int {
        // Approximate inverse of Epley formula
        let fraction = percentage / 100.0
        guard fraction > 0 && fraction <= 1 else { return 1 }
        let reps = 30.0 * (1.0 / fraction - 1.0)
        return max(1, Int(reps.rounded()))
    }
}
