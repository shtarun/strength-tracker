import Foundation

/// Utility for fuzzy matching exercise names from AI-generated content to the exercise library
enum ExerciseMatcher {
    /// Find the best matching exercise from the library using fuzzy matching
    /// - Parameters:
    ///   - name: The exercise name to search for (e.g., from AI response)
    ///   - exercises: The available exercises in the library
    /// - Returns: The best matching exercise, or nil if no suitable match is found
    static func findBestMatch(name: String, in exercises: [Exercise]) -> Exercise? {
        let searchName = name.lowercased()

        // 1. Exact match
        if let exact = exercises.first(where: { $0.name.lowercased() == searchName }) {
            return exact
        }

        // 2. Contains match (e.g., "Barbell Bench Press" contains "Bench Press")
        if let contains = exercises.first(where: { searchName.contains($0.name.lowercased()) }) {
            return contains
        }

        // 3. Reverse contains match (e.g., "Bench Press" is contained in "Barbell Bench Press")
        if let reverseContains = exercises.first(where: { $0.name.lowercased().contains(searchName) }) {
            return reverseContains
        }

        // 4. Word-based matching - find exercise with most matching words
        let searchWords = Set(searchName.split(separator: " ").map { String($0) })
        var bestMatch: Exercise?
        var bestScore = 0

        for exercise in exercises {
            let exerciseWords = Set(exercise.name.lowercased().split(separator: " ").map { String($0) })
            let commonWords = searchWords.intersection(exerciseWords)
            let score = commonWords.count

            // Require at least 1 matching word
            if score > bestScore && score >= 1 {
                bestScore = score
                bestMatch = exercise
            }
        }

        if bestMatch != nil {
            return bestMatch
        }

        // 5. Common name variations - strip common prefixes/suffixes
        let prefixesToStrip = ["barbell", "dumbbell", "cable", "machine", "seated", "standing", "incline", "decline", "flat", "ez", "close-grip", "wide-grip"]
        var strippedSearch = searchName
        for prefix in prefixesToStrip {
            strippedSearch = strippedSearch.replacingOccurrences(of: prefix + " ", with: "")
            strippedSearch = strippedSearch.replacingOccurrences(of: prefix + "-", with: "")
        }
        strippedSearch = strippedSearch.trimmingCharacters(in: .whitespaces)

        if !strippedSearch.isEmpty && strippedSearch != searchName {
            for exercise in exercises {
                let exerciseName = exercise.name.lowercased()
                if exerciseName == strippedSearch || exerciseName.contains(strippedSearch) || strippedSearch.contains(exerciseName) {
                    return exercise
                }
            }
        }

        // 6. Try matching common abbreviations and synonyms
        let synonyms: [String: [String]] = [
            "bench press": ["chest press", "flat bench", "bb bench"],
            "squat": ["back squat", "barbell squat", "bb squat"],
            "deadlift": ["conventional deadlift", "bb deadlift"],
            "ohp": ["overhead press", "shoulder press", "military press"],
            "row": ["bent over row", "barbell row", "bb row"],
            "pull-up": ["pullup", "chin-up", "chinup"],
            "lat pulldown": ["pulldown", "lat pull"],
            "tricep": ["triceps"],
            "bicep": ["biceps"],
            "rdl": ["romanian deadlift"],
            "sldl": ["stiff leg deadlift", "stiff-leg deadlift"]
        ]

        for (canonical, alternatives) in synonyms {
            if alternatives.contains(searchName) || searchName.contains(canonical) {
                if let match = exercises.first(where: { $0.name.lowercased().contains(canonical) }) {
                    return match
                }
            }
            for alt in alternatives where searchName.contains(alt) {
                if let match = exercises.first(where: { $0.name.lowercased().contains(canonical) }) {
                    return match
                }
            }
        }

        return nil
    }
}
