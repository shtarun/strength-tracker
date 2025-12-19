import Foundation

class OpenAIProvider: LLMProvider {
    let providerType: LLMProviderType = .openai
    private let apiKey: String
    private let model = "gpt-4o-mini"
    private let baseURL = "https://api.openai.com/v1/chat/completions"

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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "max_completion_tokens": maxTokens,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": CoachPrompts.systemPrompt],
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

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw LLMError.noContent
        }

        return content
    }

    private func parseResponse<T: Decodable>(_ response: String) throws -> T {
        // Clean up response
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

// MARK: - OpenAI Response Types

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String?
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
