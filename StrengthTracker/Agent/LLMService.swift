import Foundation

// MARK: - LLM Provider Protocol

protocol LLMProvider {
    var providerType: LLMProviderType { get }
    func generatePlan(context: CoachContext) async throws -> TodayPlanResponse
    func generateInsight(session: SessionSummary) async throws -> InsightResponse
    func analyzeStall(context: StallContext) async throws -> StallAnalysisResponse
    func generateWeeklyReview(context: WeeklyReviewContext) async throws -> WeeklyReviewResponse
    func generateCustomWorkout(request: CustomWorkoutRequest) async throws -> CustomWorkoutResponse
    func generateWorkoutPlan(request: GeneratePlanRequest) async throws -> GeneratedPlanResponse
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

// MARK: - Custom Workout Types

struct CustomWorkoutRequest: Codable {
    let userPrompt: String
    let availableExercises: [AvailableExerciseInfo]
    let equipmentAvailable: [String]
    let userGoal: String
    let location: String
    let timeAvailable: Int
    let recentExerciseHistory: [String: Double] // exerciseName: lastE1RM
}

struct AvailableExerciseInfo: Codable {
    let name: String
    let movementPattern: String
    let primaryMuscles: [String]
    let isCompound: Bool
    let equipmentRequired: [String]
}

struct CustomWorkoutResponse: Codable {
    let workoutName: String
    let exercises: [CustomExercisePlan]
    let reasoning: String
    let estimatedDuration: Int
    let focusAreas: [String]
}

struct CustomExercisePlan: Codable {
    let exerciseName: String
    let sets: Int
    let reps: String // e.g., "8-10" or "5"
    let rpeCap: Double
    let notes: String?
    let suggestedWeight: Double? // Based on history if available
    
    // Exercise metadata for creating new exercises if not in library
    let movementPattern: String? // e.g., "horizontalPush", "squat", "hinge"
    let primaryMuscles: [String]? // e.g., ["chest", "triceps"]
    let isCompound: Bool?
    let equipmentRequired: [String]? // e.g., ["barbell", "bench"]
    let youtubeVideoURL: String? // Form tutorial video URL (prefer AthleanX)
    
    init(
        exerciseName: String,
        sets: Int,
        reps: String,
        rpeCap: Double,
        notes: String? = nil,
        suggestedWeight: Double? = nil,
        movementPattern: String? = nil,
        primaryMuscles: [String]? = nil,
        isCompound: Bool? = nil,
        equipmentRequired: [String]? = nil,
        youtubeVideoURL: String? = nil
    ) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.rpeCap = rpeCap
        self.notes = notes
        self.suggestedWeight = suggestedWeight
        self.movementPattern = movementPattern
        self.primaryMuscles = primaryMuscles
        self.isCompound = isCompound
        self.equipmentRequired = equipmentRequired
        self.youtubeVideoURL = youtubeVideoURL
    }
    
    var repsMin: Int {
        let parts = reps.split(separator: "-")
        return Int(parts.first ?? "8") ?? 8
    }
    
    var repsMax: Int {
        let parts = reps.split(separator: "-")
        return Int(parts.last ?? "10") ?? 10
    }
}

// MARK: - Workout Plan Generation Types

struct GeneratePlanRequest: Codable {
    let goal: Goal
    let durationWeeks: Int
    let daysPerWeek: Int
    let split: Split
    let equipment: [Equipment]
    let includeDeloads: Bool
    let focusAreas: [Muscle]?
}

struct GeneratedPlanResponse: Codable {
    let planName: String
    let description: String
    let weeks: [GeneratedWeek]
    let coachingNotes: String
}

struct GeneratedWeek: Codable {
    let weekNumber: Int
    let weekType: String // "regular", "deload", "peak", "test"
    let workouts: [GeneratedWorkout]
    let weekNotes: String?
}

struct GeneratedWorkout: Codable {
    let dayNumber: Int
    let name: String
    let exercises: [GeneratedExercise]
    let targetDuration: Int
}

struct GeneratedExercise: Codable {
    let exerciseName: String
    let sets: Int
    let repsMin: Int
    let repsMax: Int
    let rpe: Double?
    let notes: String?
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

    func generateCustomWorkout(
        request: CustomWorkoutRequest,
        provider: LLMProviderType
    ) async throws -> CustomWorkoutResponse {
        isLoading = true
        defer { isLoading = false }

        if provider != .offline, let llmProvider = getProvider(for: provider) {
            do {
                return try await llmProvider.generateCustomWorkout(request: request)
            } catch {
                lastError = "LLM unavailable: \(error.localizedDescription)"
                throw error
            }
        }

        // Custom workouts require LLM - no offline fallback
        throw LLMError.noProvider("Custom workouts require an AI provider. Please configure Claude or OpenAI in Settings.")
    }
    
    func generateWorkoutPlan(
        request: GeneratePlanRequest,
        provider: LLMProviderType
    ) async throws -> GeneratedPlanResponse {
        isLoading = true
        defer { isLoading = false }
        
        if provider != .offline, let llmProvider = getProvider(for: provider) {
            do {
                return try await llmProvider.generateWorkoutPlan(request: request)
            } catch {
                lastError = "LLM unavailable: \(error.localizedDescription)"
                throw error
            }
        }
        
        // Workout plan generation requires LLM - no offline fallback
        throw LLMError.noProvider("Plan generation requires an AI provider. Please configure Claude or OpenAI in Settings.")
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
    - Pain flags (body parts with pain, severity, associated exercises)

    Rules:
    1. Prefer stable, predictable plans - avoid random variation
    2. Make the smallest effective change to drive progress
    3. Never exceed user's available equipment
    4. CRITICAL - Pain flags are the highest priority:
       - If an exercise targets a body part with an active pain flag, ALWAYS substitute it
       - IMPORTANT: Choose substitutes from COMPLETELY DIFFERENT body parts
       - Upper body pain (chest/shoulders/back/arms) → substitute with LEG exercises
       - Leg pain → substitute with UPPER BODY exercises (back/chest preferred)
       - Core pain → substitute with limb exercises (legs/arms)
       - Severity matters: Mild = consider lighter load, Moderate/Severe = MUST substitute
       - Prefer compound movements for substitutes when possible
       - Include clear reasoning in the "substitutions" array explaining the pain-based swap
       - Never ignore pain flags - user safety is paramount
    5. Respect readiness flags:
       - Low energy or high soreness: cap RPE at 7.5, reduce backoffs by 1-2 sets
       - High energy + no soreness: allow 1 extra backoff or small load bump
    6. For weight progressions:
       - Barbell compounds: +2.5kg when rep target hit at/below RPE cap
       - Dumbbells: +2kg (or next available increment)
       - If reps not hit, keep weight and aim for +1 rep
    7. Always output valid JSON matching the provided schema exactly
    8. Never add exercises not in the template unless absolutely necessary

    Output JSON only. No markdown code fences, no explanations outside the JSON structure.
    """

    static let planPrompt = """
    Generate today's workout plan based on the context provided.

    CRITICAL - Check for pain flags first:
    1. Review all painFlags in the context
    2. For each exercise in the template, check if it targets the affected body part
    3. If pain flag severity is Moderate or Severe, MUST substitute the exercise
    4. If severity is Mild, consider reducing load by 10-15% or substituting
    5. SUBSTITUTION STRATEGY - Use exercises from different body parts:
       - Upper body pain → substitute with leg exercises (squats, lunges, leg press)
       - Leg pain → substitute with upper body (rows, pull-ups, lat pulldown)
       - Never substitute shoulder pain with another shoulder exercise!
    6. Document ALL substitutions in the "substitutions" array with clear reasoning

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

    static let customWorkoutPrompt = """
    Create a custom workout based on the user's natural language request.

    Guidelines:
    1. ONLY use exercises from the provided availableExercises list
    2. Match exercises to the user's equipment
    3. Respect the time constraint - estimate ~3-4 min per working set including rest
    4. Select exercises that fit the user's request (muscle groups, workout type, etc.)
    5. For compound exercises: 3-5 working sets
    6. For isolation exercises: 2-3 working sets
    7. Use the user's exercise history to suggest appropriate weights
    8. Order exercises: compounds first, then isolations
    9. Include YouTube form tutorial URLs - prefer AthleanX videos when available

    Respond with valid JSON:
    {
      "workoutName": "string (descriptive name)",
      "exercises": [
        {
          "exerciseName": "string (prefer exercises from availableExercises, but can suggest others)",
          "sets": number,
          "reps": "string (e.g., '8-10' or '5')",
          "rpeCap": number (7-9),
          "notes": "string or null",
          "suggestedWeight": number or null,
          "movementPattern": "string (one of: squat, hinge, lunge, horizontalPush, horizontalPull, verticalPush, verticalPull, carry, isolation, core)",
          "primaryMuscles": ["string (e.g., 'chest', 'back', 'quads', 'hamstrings', 'shoulders', 'biceps', 'triceps', 'glutes', 'calves', 'abs', 'forearms', 'traps', 'lats')"],
          "isCompound": boolean,
          "equipmentRequired": ["string (e.g., 'barbell', 'dumbbell', 'cable', 'machine', 'bodyweight', 'bench', 'rack')"],
          "youtubeVideoURL": "string or null (YouTube form tutorial URL, prefer AthleanX channel)"
        }
      ],
      "reasoning": "string (brief explanation of exercise selection)",
      "estimatedDuration": number (minutes),
      "focusAreas": ["string (muscle groups targeted)"]
    }
    """
    
    static let workoutPlanPrompt = """
    Generate a complete multi-week workout plan based on the user's specifications.
    
    Guidelines:
    1. Create a structured plan with appropriate progression
    2. Include deload weeks if requested (typically every 4th week)
    3. Match exercises to the user's available equipment
    4. Use appropriate rep ranges for the goal:
       - Strength: 3-6 reps, RPE 7-9
       - Hypertrophy: 8-12 reps, RPE 7-8.5
       - Both: Mix of both ranges across exercises
    5. Structure workouts based on the split:
       - Upper/Lower: Upper A, Lower A, Upper B, Lower B
       - PPL: Push, Pull, Legs (repeated)
       - Full Body: Full Body A, B, C
    6. Include compound movements first, then accessories
    7. Balance push/pull movements
    8. Focus extra volume on requested muscle groups
    
    Respond with valid JSON:
    {
      "planName": "string (descriptive name based on goal and duration)",
      "description": "string (brief description of the program focus)",
      "weeks": [
        {
          "weekNumber": number,
          "weekType": "regular" | "deload" | "peak" | "test",
          "workouts": [
            {
              "dayNumber": number (1-7),
              "name": "string (e.g., 'Upper A', 'Push Day')",
              "exercises": [
                {
                  "exerciseName": "string",
                  "sets": number,
                  "repsMin": number,
                  "repsMax": number,
                  "rpe": number or null,
                  "notes": "string or null"
                }
              ],
              "targetDuration": number (minutes)
            }
          ],
          "weekNotes": "string or null (coaching cues for the week)"
        }
      ],
      "coachingNotes": "string (overall program guidance)"
    }
    """
}
