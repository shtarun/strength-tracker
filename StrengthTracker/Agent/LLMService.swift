import Foundation

// MARK: - LLM Provider Protocol

protocol LLMProvider {
    var providerType: LLMProviderType { get }
    func generatePlan(context: CoachContext) async throws -> TodayPlanResponse
    func generateInsight(session: SessionSummary) async throws -> InsightResponse
    func analyzeStall(context: StallContext) async throws -> StallAnalysisResponse
    func generateWeeklyReview(context: WeeklyReviewContext) async throws -> WeeklyReviewResponse
}

// MARK: - Request/Response Types

struct CoachContext: Codable {
    let userGoal: String
    let currentTemplate: TemplateContext
    let location: String
    let readiness: ReadinessContext
    let timeAvailable: Int
    let recentHistory: [ExerciseHistoryContext]
    let equipmentAvailable: [String]
    let painFlags: [PainFlagContext]
}

struct TemplateContext: Codable {
    let name: String
    let exercises: [TemplateExerciseContext]
}

struct TemplateExerciseContext: Codable {
    let name: String
    let prescription: PrescriptionContext
    let isOptional: Bool
}

struct PrescriptionContext: Codable {
    let progressionType: String
    let topSetRepsRange: String
    let topSetRPECap: Double
    let backoffSets: Int
    let backoffRepsRange: String
    let backoffLoadDropPercent: Double
}

struct ReadinessContext: Codable {
    let energy: String
    let soreness: String
}

struct ExerciseHistoryContext: Codable {
    let exerciseName: String
    let lastSessions: [SessionHistoryContext]
}

struct SessionHistoryContext: Codable {
    let date: String
    let topSetWeight: Double
    let topSetReps: Int
    let topSetRPE: Double?
    let totalSets: Int
    let e1RM: Double
}

struct PainFlagContext: Codable {
    let exerciseName: String?
    let bodyPart: String
    let severity: String
}

struct SessionSummary: Codable {
    let templateName: String
    let exercises: [ExerciseSummary]
    let readiness: ReadinessContext
    let totalVolume: Double
    let duration: Int
}

struct ExerciseSummary: Codable {
    let name: String
    let topSet: SetSummary?
    let backoffSets: [SetSummary]
    let targetHit: Bool
    let e1RM: Double
    let previousE1RM: Double?
}

struct SetSummary: Codable {
    let weight: Double
    let reps: Int
    let rpe: Double?
    let targetReps: Int
}

struct StallContext: Codable {
    let exerciseName: String
    let lastSessions: [SessionHistoryContext]
    let currentPrescription: PrescriptionContext
    let userGoal: String
}

// MARK: - Response Types

struct TodayPlanResponse: Codable {
    let exercises: [PlannedExerciseResponse]
    let substitutions: [SubstitutionResponse]
    let adjustments: [String]
    let reasoning: [String]
    let estimatedDuration: Int
}

struct PlannedExerciseResponse: Codable {
    let exerciseName: String
    let warmupSets: [PlannedSetResponse]
    let topSet: PlannedSetResponse?
    let backoffSets: [PlannedSetResponse]
    let workingSets: [PlannedSetResponse]
}

struct PlannedSetResponse: Codable {
    let weight: Double
    let reps: Int
    let rpeCap: Double?
    let setCount: Int
}

struct SubstitutionResponse: Codable {
    let from: String
    let to: String
    let reason: String
}

struct InsightResponse: Codable {
    let insight: String
    let action: String
    let category: String // "progress", "fatigue", "technique", "volume"
}

struct StallAnalysisResponse: Codable {
    let isStalled: Bool
    let reason: String?
    let suggestedFix: String?
    let fixType: String? // "deload", "rep_range", "variation", "volume"
    let details: String?
}

struct WeeklyReviewResponse: Codable {
    let summary: String
    let highlights: [String]
    let areasToImprove: [String]
    let recommendation: String
    let consistencyScore: Int // 1-10
}

struct WeeklyReviewContext: Codable {
    let workoutCount: Int
    let totalVolume: Double
    let averageDuration: Int
    let exerciseHighlights: [WeeklyExerciseHighlight]
    let userGoal: String
}

struct WeeklyExerciseHighlight: Codable {
    let exerciseName: String
    let sessions: Int
    let bestE1RM: Double
    let previousBestE1RM: Double?
    let totalVolume: Double
}

// MARK: - LLM Service Manager

@MainActor
class LLMService: ObservableObject {
    static let shared = LLMService()

    @Published var isLoading = false
    @Published var lastError: String?

    private var claudeProvider: ClaudeProvider?
    private var openAIProvider: OpenAIProvider?
    private let offlineEngine = OfflineProgressionEngine()

    private init() {}

    func configure(claudeAPIKey: String?, openAIAPIKey: String?) {
        if let key = claudeAPIKey, !key.isEmpty {
            claudeProvider = ClaudeProvider(apiKey: key)
        }
        if let key = openAIAPIKey, !key.isEmpty {
            openAIProvider = OpenAIProvider(apiKey: key)
        }
    }

    func getProvider(for type: LLMProviderType) -> LLMProvider? {
        switch type {
        case .claude: return claudeProvider
        case .openai: return openAIProvider
        case .offline: return nil
        }
    }

    func generatePlan(
        context: CoachContext,
        provider: LLMProviderType
    ) async throws -> TodayPlanResponse {
        isLoading = true
        defer { isLoading = false }

        // Try LLM first, fall back to offline
        if provider != .offline, let llmProvider = getProvider(for: provider) {
            do {
                return try await llmProvider.generatePlan(context: context)
            } catch {
                lastError = "LLM unavailable, using offline mode: \(error.localizedDescription)"
                // Fall through to offline
            }
        }

        // Offline fallback
        return await offlineEngine.generatePlan(context: context)
    }

    func generateInsight(
        session: SessionSummary,
        provider: LLMProviderType
    ) async throws -> InsightResponse {
        isLoading = true
        defer { isLoading = false }

        if provider != .offline, let llmProvider = getProvider(for: provider) {
            do {
                return try await llmProvider.generateInsight(session: session)
            } catch {
                lastError = "LLM unavailable, using offline mode"
            }
        }

        return await offlineEngine.generateInsight(session: session)
    }

    func analyzeStall(
        context: StallContext,
        provider: LLMProviderType
    ) async throws -> StallAnalysisResponse {
        isLoading = true
        defer { isLoading = false }

        if provider != .offline, let llmProvider = getProvider(for: provider) {
            do {
                return try await llmProvider.analyzeStall(context: context)
            } catch {
                lastError = "LLM unavailable, using offline mode"
            }
        }

        return await offlineEngine.analyzeStall(context: context)
    }

    func generateWeeklyReview(
        context: WeeklyReviewContext,
        provider: LLMProviderType
    ) async throws -> WeeklyReviewResponse {
        isLoading = true
        defer { isLoading = false }

        if provider != .offline, let llmProvider = getProvider(for: provider) {
            do {
                return try await llmProvider.generateWeeklyReview(context: context)
            } catch {
                lastError = "LLM unavailable, using offline mode"
            }
        }

        return await offlineEngine.generateWeeklyReview(context: context)
    }
}

// MARK: - System Prompt

enum CoachPrompts {
    static let systemPrompt = """
    You are a strength coach for intermediate lifters. You have access to the user's:
    - Training history (exercises, sets, weights, reps, RPE)
    - Equipment profile (gym/home, available gear)
    - Current readiness (energy, soreness, time)
    - Goals (strength/hypertrophy/both)

    Rules:
    1. Prefer stable, predictable plans - avoid random variation
    2. Make the smallest effective change to drive progress
    3. Never exceed user's available equipment
    4. Respect readiness flags:
       - Low energy or high soreness: cap RPE at 7.5, reduce backoffs by 1-2 sets
       - High energy + no soreness: allow 1 extra backoff or small load bump
    5. For weight progressions:
       - Barbell compounds: +2.5kg when rep target hit at/below RPE cap
       - Dumbbells: +2kg (or next available increment)
       - If reps not hit, keep weight and aim for +1 rep
    6. Always output valid JSON matching the provided schema exactly
    7. Never add exercises not in the template unless absolutely necessary

    Output JSON only. No markdown code fences, no explanations outside the JSON structure.
    """

    static let planPrompt = """
    Generate today's workout plan based on the context provided.

    For each exercise:
    1. Calculate warmup sets (typically 3-4 sets working up to top set weight)
    2. Set the top set target based on recent history and readiness
    3. Calculate backoff sets (typically 8-12% lighter than top set)
    4. Note any substitutions needed due to equipment or pain

    Respond with valid JSON matching this schema:
    {
      "exercises": [
        {
          "exerciseName": "string",
          "warmupSets": [{"weight": number, "reps": number, "rpeCap": number, "setCount": number}],
          "topSet": {"weight": number, "reps": number, "rpeCap": number, "setCount": number},
          "backoffSets": [{"weight": number, "reps": number, "rpeCap": number, "setCount": number}],
          "workingSets": [{"weight": number, "reps": number, "rpeCap": number, "setCount": number}]
        }
      ],
      "substitutions": [{"from": "string", "to": "string", "reason": "string"}],
      "adjustments": ["string"],
      "reasoning": ["string"],
      "estimatedDuration": number
    }
    """

    static let insightPrompt = """
    Generate a single insight and actionable recommendation for this completed workout.

    Focus on:
    - Progress: any PRs, rep PRs, or e1RM improvements
    - Fatigue: missed reps, high RPE, reduced volume
    - Next steps: what to do next session

    Respond with valid JSON:
    {
      "insight": "string (one sentence observation)",
      "action": "string (one sentence recommendation)",
      "category": "progress" | "fatigue" | "technique" | "volume"
    }
    """

    static let stallPrompt = """
    Analyze if this exercise is stalled and suggest a fix if needed.

    Stall criteria:
    - No e1RM improvement for 3+ exposures (or 2+ weeks)
    - Consistently missing rep targets
    - RPE creeping above cap

    Suggest ONE fix:
    - Micro-deload (7-10% reduction)
    - Rep range change (e.g., 4-6 → 6-8)
    - Variation swap (similar movement pattern)
    - Volume tweak (add/remove sets)

    Respond with valid JSON:
    {
      "isStalled": boolean,
      "reason": "string or null",
      "suggestedFix": "string or null",
      "fixType": "deload" | "rep_range" | "variation" | "volume" | null,
      "details": "string or null"
    }
    """

    static let weeklyReviewPrompt = """
    Generate a weekly training review based on the completed workouts.

    Analyze:
    - Consistency (workouts completed vs expected)
    - Progress (PRs, e1RM improvements)
    - Volume trends (increasing, stable, decreasing)
    - Recovery signals (RPE trends, missed reps)

    Provide:
    - A brief summary paragraph
    - 2-3 highlights (positive things)
    - 1-2 areas to improve
    - One actionable recommendation for next week
    - A consistency score (1-10)

    Respond with valid JSON:
    {
      "summary": "string (2-3 sentences)",
      "highlights": ["string"],
      "areasToImprove": ["string"],
      "recommendation": "string (one actionable item)",
      "consistencyScore": number
    }
    """
}
