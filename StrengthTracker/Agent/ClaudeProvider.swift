import Foundation

class ClaudeProvider: LLMProvider {
    let providerType: LLMProviderType = .claude
    private let apiKey: String
    private let model = "claude-sonnet-4-20250514"
    private let baseURL = "https://api.anthropic.com/v1/messages"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generatePlan(context: CoachContext) async throws -> TodayPlanResponse {
        let userMessage = """
        Context:
        \(try jsonString(from: context))

        \(CoachPrompts.planPrompt)
        """

        let response = try await sendMessage(userMessage)
        return try parseResponse(response)
    }

    func generateInsight(session: SessionSummary) async throws -> InsightResponse {
        let userMessage = """
        Workout Summary:
        \(try jsonString(from: session))

        \(CoachPrompts.insightPrompt)
        """

        let response = try await sendMessage(userMessage)
        return try parseResponse(response)
    }

    func analyzeStall(context: StallContext) async throws -> StallAnalysisResponse {
        let userMessage = """
        Stall Analysis Context:
        \(try jsonString(from: context))

        \(CoachPrompts.stallPrompt)
        """

        let response = try await sendMessage(userMessage)
        return try parseResponse(response)
    }

    func generateWeeklyReview(context: WeeklyReviewContext) async throws -> WeeklyReviewResponse {
        let userMessage = """
        Weekly Training Data:
        \(try jsonString(from: context))

        \(CoachPrompts.weeklyReviewPrompt)
        """

        let response = try await sendMessage(userMessage)
        return try parseResponse(response)
    }

    func generateCustomWorkout(request: CustomWorkoutRequest) async throws -> CustomWorkoutResponse {
        let userMessage = """
        User Request: "\(request.userPrompt)"

        Time Available: \(request.timeAvailable) minutes
        Location: \(request.location)
        User Goal: \(request.userGoal)
        Equipment Available: \(request.equipmentAvailable.joined(separator: ", "))

        Available Exercises:
        \(try jsonString(from: request.availableExercises))

        Recent Exercise History (name: lastE1RM):
        \(request.recentExerciseHistory.map { "\($0.key): \($0.value)kg" }.joined(separator: "\n"))

        \(CoachPrompts.customWorkoutPrompt)
        """

        let response = try await sendMessage(userMessage)
        return try parseResponse(response)
    }
    
    func generateWorkoutPlan(request: GeneratePlanRequest) async throws -> GeneratedPlanResponse {
        let focusAreasText = request.focusAreas?.map { $0.rawValue }.joined(separator: ", ") ?? "None specified"
        
        let userMessage = """
        Generate a complete \(request.durationWeeks)-week workout plan.
        
        User Specifications:
        - Goal: \(request.goal.rawValue)
        - Duration: \(request.durationWeeks) weeks
        - Training Days per Week: \(request.daysPerWeek)
        - Preferred Split: \(request.split.rawValue)
        - Available Equipment: \(request.equipment.map { $0.rawValue }.joined(separator: ", "))
        - Include Deload Weeks: \(request.includeDeloads ? "Yes (recommend every 4th week)" : "No")
        - Focus Areas: \(focusAreasText)
        
        \(CoachPrompts.workoutPlanPrompt)
        """
        
        // Use higher token limit for plan generation (plans can be large)
        let response = try await sendMessage(userMessage, maxTokens: 16384)
        return try parseResponse(response)
    }

    private func sendMessage(_ userMessage: String, maxTokens: Int = 4096) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 180 // 3 minutes timeout for large AI generation
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": CoachPrompts.systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let content = claudeResponse.content.first?.text else {
            throw LLMError.noContent
        }

        return content
    }

    private func parseResponse<T: Decodable>(_ response: String) throws -> T {
        // Clean up response - remove markdown code fences if present
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle various markdown wrapping formats
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract JSON from response if it's mixed with text
        if let jsonStart = cleaned.firstIndex(of: "{"),
           let jsonEnd = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[jsonStart...jsonEnd])
        }

        guard let data = cleaned.data(using: .utf8) else {
            throw LLMError.parseError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            let errorDetail: String
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorDetail = "Missing key '\(key.stringValue)' at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorDetail = "Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorDetail = "Missing value of type \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorDetail = "Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
            @unknown default:
                errorDetail = decodingError.localizedDescription
            }
            print("🔴 JSON Parse Error: \(errorDetail)")
            print("🔴 Raw response (first 500 chars): \(String(cleaned.prefix(500)))")
            throw LLMError.parseError("JSON decode failed: \(errorDetail)")
        } catch {
            throw LLMError.parseError("JSON decode failed: \(error.localizedDescription)")
        }
    }

    private func jsonString<T: Encodable>(from value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - Claude Response Types

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let usage: ClaudeUsage

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String?
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - LLM Errors

enum LLMError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContent
    case parseError(String)
    case noProvider(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .noContent:
            return "No content in response"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .noProvider(let message):
            return message
        }
    }
}
