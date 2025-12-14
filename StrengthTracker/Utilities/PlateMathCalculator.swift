import Foundation

enum PlateMathCalculator {
    /// Standard available plate pairs (each side) in kg
    static let standardPlates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    /// Calculate plates needed per side for a target weight
    /// - Parameters:
    ///   - targetWeight: Total barbell weight including bar
    ///   - barWeight: Weight of the empty bar (default 20kg)
    ///   - availablePlates: Plate pairs available (default standard)
    /// - Returns: Array of plate weights per side, or nil if impossible
    static func platesPerSide(
        targetWeight: Double,
        barWeight: Double = 20.0,
        availablePlates: [Double] = standardPlates
    ) -> [Double]? {
        let weightToLoad = targetWeight - barWeight

        guard weightToLoad >= 0 else { return nil }
        guard weightToLoad.truncatingRemainder(dividingBy: 2) == 0 ||
              availablePlates.contains(1.25) else {
            // Can't split odd weight without 1.25kg plates
            return nil
        }

        var remaining = weightToLoad / 2 // Weight per side
        var plates: [Double] = []

        // Greedy algorithm - largest plates first
        let sortedPlates = availablePlates.sorted(by: >)

        for plate in sortedPlates {
            while remaining >= plate {
                plates.append(plate)
                remaining -= plate
            }
        }

        // Check if we loaded exactly what we needed
        if abs(remaining) < 0.001 {
            return plates
        }

        return nil
    }

    /// Format plates for display
    /// - Parameter plates: Array of plate weights per side
    /// - Returns: Formatted string like "20 + 10 + 5"
    static func formatPlates(_ plates: [Double]) -> String {
        if plates.isEmpty {
            return "Empty bar"
        }

        return plates.map { plate in
            if plate.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(plate))"
            }
            return String(format: "%.2g", plate)
        }.joined(separator: " + ")
    }

    /// Get loading instructions
    /// - Parameters:
    ///   - targetWeight: Total target weight
    ///   - barWeight: Bar weight
    ///   - availablePlates: Available plates
    /// - Returns: Human readable loading instruction
    static func loadingInstruction(
        targetWeight: Double,
        barWeight: Double = 20.0,
        availablePlates: [Double] = standardPlates
    ) -> String {
        guard let plates = platesPerSide(
            targetWeight: targetWeight,
            barWeight: barWeight,
            availablePlates: availablePlates
        ) else {
            return "Cannot load \(targetWeight)kg with available plates"
        }

        if plates.isEmpty {
            return "Empty bar (\(Int(barWeight))kg)"
        }

        let formatted = formatPlates(plates)
        return "\(formatted) each side"
    }

    /// Round weight to nearest loadable value
    /// - Parameters:
    ///   - weight: Target weight
    ///   - availablePlates: Available plates
    ///   - barWeight: Bar weight
    /// - Returns: Nearest weight that can be loaded
    static func nearestLoadable(
        weight: Double,
        availablePlates: [Double] = standardPlates,
        barWeight: Double = 20.0
    ) -> Double {
        let smallestIncrement = (availablePlates.min() ?? 1.25) * 2
        let weightAboveBar = weight - barWeight
        let rounded = (weightAboveBar / smallestIncrement).rounded() * smallestIncrement
        return barWeight + max(0, rounded)
    }

    /// Calculate warmup weights for a top set
    /// - Parameters:
    ///   - topSetWeight: Target top set weight
    ///   - barWeight: Bar weight
    ///   - availablePlates: Available plates
    /// - Returns: Array of warmup weights
    static func warmupWeights(
        topSetWeight: Double,
        barWeight: Double = 20.0,
        availablePlates: [Double] = standardPlates
    ) -> [Double] {
        guard topSetWeight > barWeight else {
            return []
        }

        var warmups: [Double] = []

        // Empty bar if top set is heavy enough
        if topSetWeight > barWeight * 2 {
            warmups.append(barWeight)
        }

        // Progressive percentages
        let percentages: [Double] = [0.4, 0.6, 0.8]

        for percentage in percentages {
            let target = topSetWeight * percentage
            if target > barWeight {
                let loadable = nearestLoadable(
                    weight: target,
                    availablePlates: availablePlates,
                    barWeight: barWeight
                )
                // Avoid duplicates
                if !warmups.contains(loadable) && loadable < topSetWeight {
                    warmups.append(loadable)
                }
            }
        }

        return warmups.sorted()
    }
}

// MARK: - Dumbbell Helpers

extension PlateMathCalculator {
    /// Common dumbbell increments
    static let standardDumbbells: [Double] = Array(stride(from: 2.5, through: 60, by: 2.5))

    /// Find nearest available dumbbell weight
    static func nearestDumbbell(
        weight: Double,
        availableDumbbells: [Double] = standardDumbbells
    ) -> Double? {
        let sorted = availableDumbbells.sorted()

        // Find closest
        var closest: Double?
        var smallestDiff = Double.infinity

        for db in sorted {
            let diff = abs(db - weight)
            if diff < smallestDiff {
                smallestDiff = diff
                closest = db
            }
        }

        return closest
    }

    /// Get next dumbbell increment up
    static func nextDumbbellUp(
        from current: Double,
        availableDumbbells: [Double] = standardDumbbells
    ) -> Double? {
        let sorted = availableDumbbells.sorted()
        return sorted.first { $0 > current }
    }

    /// Get next dumbbell increment down
    static func nextDumbbellDown(
        from current: Double,
        availableDumbbells: [Double] = standardDumbbells
    ) -> Double? {
        let sorted = availableDumbbells.sorted(by: >)
        return sorted.first { $0 < current }
    }
}
