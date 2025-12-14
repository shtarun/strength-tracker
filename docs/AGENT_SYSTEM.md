# Agent System

This document describes the AI coaching system that powers intelligent workout recommendations in Strength Tracker.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [LLM Service](#llm-service)
- [Providers](#providers)
  - [Claude Provider](#claude-provider)
  - [OpenAI Provider](#openai-provider)
  - [Offline Progression Engine](#offline-progression-engine)
- [Context Building](#context-building)
- [Response Types](#response-types)
- [Prompts](#prompts)
- [Fallback Strategy](#fallback-strategy)

---

## Overview

The Agent System is the "brain" of Strength Tracker, responsible for:

1. **Plan Generation** - Creating personalized workout plans based on history and readiness
2. **Progression Logic** - Calculating optimal weight/rep targets
3. **Insight Generation** - Providing post-workout feedback
4. **Stall Detection** - Identifying plateaus and suggesting fixes

```
┌─────────────────────────────────────────────────────────────┐
│                     Agent System                             │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │   Claude    │    │   OpenAI    │    │  Offline Engine │ │
│  │  Provider   │    │  Provider   │    │  (Rule-based)   │ │
│  └──────┬──────┘    └──────┬──────┘    └────────┬────────┘ │
│         │                  │                    │          │
│         └──────────────────┴────────────────────┘          │
│                            │                                │
│                     ┌──────▼──────┐                        │
│                     │ LLMService  │                        │
│                     │  (Manager)  │                        │
│                     └─────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Architecture

### Component Hierarchy

```
Agent/
├── LLMService.swift              # Singleton manager
├── ClaudeProvider.swift          # Anthropic Claude API
├── OpenAIProvider.swift          # OpenAI GPT API
└── OfflineProgressionEngine.swift # Rule-based fallback
```

### Provider Protocol

All providers implement a common interface:

```swift
protocol LLMProvider {
    var providerType: LLMProviderType { get }
    
    func generatePlan(context: CoachContext) async throws -> TodayPlanResponse
    func generateInsight(session: SessionSummary) async throws -> InsightResponse
    func analyzeStall(context: StallContext) async throws -> StallAnalysisResponse
}
```

---

## LLM Service

The central manager for all AI operations.

**File:** `Agent/LLMService.swift`

### Initialization

```swift
@MainActor
class LLMService: ObservableObject {
    static let shared = LLMService()
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var claudeProvider: ClaudeProvider?
    private var openAIProvider: OpenAIProvider?
    private let offlineEngine = OfflineProgressionEngine()
}
```

### Configuration

```swift
func configure(claudeAPIKey: String?, openAIAPIKey: String?) {
    if let key = claudeAPIKey, !key.isEmpty {
        claudeProvider = ClaudeProvider(apiKey: key)
    }
    if let key = openAIAPIKey, !key.isEmpty {
        openAIProvider = OpenAIProvider(apiKey: key)
    }
}
```

### Plan Generation Flow

```swift
func generatePlan(
    context: CoachContext,
    provider: LLMProviderType
) async throws -> TodayPlanResponse {
    isLoading = true
    defer { isLoading = false }
    
    // Try LLM first
    if provider != .offline, let llmProvider = getProvider(for: provider) {
        do {
            return try await llmProvider.generatePlan(context: context)
        } catch {
            lastError = "LLM unavailable, using offline mode"
        }
    }
    
    // Fallback to offline engine
    return await offlineEngine.generatePlan(context: context)
}
```

---

## Providers

### Claude Provider

Integration with Anthropic's Claude API.

**File:** `Agent/ClaudeProvider.swift`

**Configuration:**
| Setting | Value |
|---------|-------|
| Model | `claude-sonnet-4-20250514` |
| Max Tokens | 4096 |
| API Version | `2023-06-01` |

**API Request Structure:**

```swift
let body: [String: Any] = [
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 4096,
    "system": CoachPrompts.systemPrompt,
    "messages": [
        ["role": "user", "content": userMessage]
    ]
]
```

**Headers:**

```swift
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
```

### OpenAI Provider

Integration with OpenAI's GPT API.

**File:** `Agent/OpenAIProvider.swift`

**Configuration:**
| Setting | Value |
|---------|-------|
| Model | `gpt-4o` |
| Max Tokens | 4096 |
| Temperature | 0.7 |

**API Request Structure:**

```swift
let body: [String: Any] = [
    "model": "gpt-4o",
    "max_tokens": 4096,
    "temperature": 0.7,
    "messages": [
        ["role": "system", "content": CoachPrompts.systemPrompt],
        ["role": "user", "content": userMessage]
    ]
]
```

### Offline Progression Engine

Rule-based engine for offline/fallback mode.

**File:** `Agent/OfflineProgressionEngine.swift`

**Key Features:**

1. **No external dependencies** - Works without internet
2. **Deterministic** - Same input always produces same output
3. **Fast** - No network latency

**Core Algorithm:**

```swift
actor OfflineProgressionEngine {
    
    func generatePlan(context: CoachContext) async -> TodayPlanResponse {
        var exercises: [PlannedExerciseResponse] = []
        
        // 1. Parse readiness
        let readiness = Readiness(
            energy: EnergyLevel(rawValue: context.readiness.energy) ?? .ok,
            soreness: SorenessLevel(rawValue: context.readiness.soreness) ?? .none,
            timeAvailable: context.timeAvailable
        )
        
        // 2. Apply readiness adjustments
        if readiness.shouldReduceIntensity {
            adjustments.append("Reduced intensity")
        }
        
        // 3. Plan each exercise
        for templateExercise in context.currentTemplate.exercises {
            // Skip optional exercises if time-constrained
            if templateExercise.isOptional && context.timeAvailable <= 45 {
                continue
            }
            
            let plannedExercise = planExercise(
                name: templateExercise.name,
                prescription: templateExercise.prescription,
                history: findHistory(for: templateExercise.name),
                readiness: readiness
            )
            
            exercises.append(plannedExercise)
        }
        
        return TodayPlanResponse(
            exercises: exercises,
            substitutions: [],
            adjustments: adjustments,
            reasoning: reasoning,
            estimatedDuration: calculateDuration(exercises: exercises)
        )
    }
}
```

**Progression Rules:**

| Condition | Action |
|-----------|--------|
| Hit max reps at/below RPE cap | Increase weight, reset to min reps |
| In rep range, below RPE cap | Add 1 rep at same weight |
| Below min reps or above RPE | Keep weight, focus on hitting target |
| Low energy or high soreness | Cap RPE at 7.5, reduce backoffs by 1 |
| High energy, no soreness | Allow +0.5 RPE, add 1 backoff |

**Warmup Generation:**

```swift
func generateWarmups(topSetWeight: Double) -> [PlannedSetResponse] {
    // Empty bar: 1×10
    // 40% working: 1×5
    // 60% working: 1×5
    // 80% working: 1×3
}
```

---

## Context Building

### CoachContext

The main input structure for plan generation.

```swift
struct CoachContext: Codable {
    let userGoal: String                    // "Strength", "Hypertrophy", "Both"
    let currentTemplate: TemplateContext    // Today's workout template
    let location: String                    // "Gym", "Home"
    let readiness: ReadinessContext         // Energy, soreness
    let timeAvailable: Int                  // Minutes
    let recentHistory: [ExerciseHistoryContext]  // Last sessions per exercise
    let equipmentAvailable: [String]        // Available gear
    let painFlags: [PainFlagContext]        // Active injuries
}
```

### Building Context from App Data

```swift
func buildCoachContext(template: WorkoutTemplate, readiness: Readiness) -> CoachContext {
    // 1. Get exercise history
    let exerciseHistory = template.sortedExercises.compactMap { templateEx in
        guard let exercise = templateEx.exercise else { return nil }
        
        let history = getRecentHistory(for: exercise)
        return ExerciseHistoryContext(
            exerciseName: exercise.name,
            lastSessions: history
        )
    }
    
    // 2. Get equipment list
    let equipmentList = profile?.equipmentProfile?.availableEquipment.map { $0.rawValue } ?? []
    
    // 3. Get pain flags
    let painFlags = getActivePainFlags().map { flag in
        PainFlagContext(
            exerciseName: flag.exercise?.name,
            bodyPart: flag.bodyPart,
            severity: flag.severity.rawValue
        )
    }
    
    return CoachContext(
        userGoal: profile?.goal.rawValue ?? "Both",
        currentTemplate: TemplateContext(
            name: template.name,
            exercises: template.sortedExercises.compactMap { ... }
        ),
        location: profile?.equipmentProfile?.location.rawValue ?? "Gym",
        readiness: ReadinessContext(
            energy: readiness.energy.rawValue,
            soreness: readiness.soreness.rawValue
        ),
        timeAvailable: readiness.timeAvailable,
        recentHistory: exerciseHistory,
        equipmentAvailable: equipmentList,
        painFlags: painFlags
    )
}
```

---

## Response Types

### TodayPlanResponse

The main workout plan output.

```swift
struct TodayPlanResponse: Codable {
    let exercises: [PlannedExerciseResponse]  // Exercise-by-exercise plan
    let substitutions: [SubstitutionResponse] // Exercise swaps made
    let adjustments: [String]                  // Readiness-based changes
    let reasoning: [String]                    // Explanation of decisions
    let estimatedDuration: Int                 // Minutes
}
```

### PlannedExerciseResponse

Individual exercise plan.

```swift
struct PlannedExerciseResponse: Codable {
    let exerciseName: String
    let warmupSets: [PlannedSetResponse]      // Progressive warmups
    let topSet: PlannedSetResponse?           // Primary working set
    let backoffSets: [PlannedSetResponse]     // Volume sets
    let workingSets: [PlannedSetResponse]     // For double progression
}
```

### PlannedSetResponse

Individual set prescription.

```swift
struct PlannedSetResponse: Codable {
    let weight: Double     // kg
    let reps: Int          // Target reps
    let rpeCap: Double?    // Maximum RPE
    let setCount: Int      // Number of sets at this spec
}
```

### InsightResponse

Post-workout feedback.

```swift
struct InsightResponse: Codable {
    let insight: String    // "Bench Press e1RM improved 3%"
    let action: String     // "Add 2.5kg next session"
    let category: String   // "progress", "fatigue", "technique", "volume"
}
```

### StallAnalysisResponse

Plateau detection result.

```swift
struct StallAnalysisResponse: Codable {
    let isStalled: Bool
    let reason: String?          // "No e1RM improvement in 3 sessions"
    let suggestedFix: String?    // "Take a micro-deload"
    let fixType: String?         // "deload", "rep_range", "variation", "volume"
    let details: String?         // "New target: 85kg"
}
```

---

## Prompts

### System Prompt

Sets the coaching personality and rules.

```swift
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

Output JSON only. No markdown code fences, no explanations outside JSON.
"""
```

### Plan Prompt

Specific instructions for workout generation.

```swift
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
```

### Insight Prompt

Post-workout analysis instructions.

```swift
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
```

### Stall Prompt

Plateau detection instructions.

```swift
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
```

---

## Fallback Strategy

The agent system uses a tiered fallback approach:

```
┌─────────────────────────────────────────────────────────────┐
│                    Request: Generate Plan                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ User's Provider │
                    │    Preference   │
                    └─────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌─────────┐     ┌─────────┐     ┌─────────┐
        │ Claude  │     │ OpenAI  │     │ Offline │
        └────┬────┘     └────┬────┘     └────┬────┘
             │               │               │
             ▼               ▼               │
      ┌─────────────┐ ┌─────────────┐       │
      │ API Success │ │ API Success │       │
      └──────┬──────┘ └──────┬──────┘       │
             │               │               │
             ▼               ▼               │
        Return Plan    Return Plan          │
                                            │
      ┌─────────────┐ ┌─────────────┐       │
      │ API Failed  │ │ API Failed  │       │
      └──────┬──────┘ └──────┬──────┘       │
             │               │               │
             └───────────────┴───────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Offline Engine  │
                    │  (Always works) │
                    └─────────────────┘
                              │
                              ▼
                        Return Plan
```

**Error Handling:**

```swift
func generatePlan(...) async throws -> TodayPlanResponse {
    if provider != .offline, let llmProvider = getProvider(for: provider) {
        do {
            return try await llmProvider.generatePlan(context: context)
        } catch {
            // Log error but don't throw
            lastError = "LLM unavailable, using offline mode: \(error.localizedDescription)"
            // Fall through to offline
        }
    }
    
    // Offline engine - guaranteed to return a plan
    return await offlineEngine.generatePlan(context: context)
}
```

---

## See Also

- [Progression Logic](PROGRESSION.md) - Training science details
- [API Reference](API_REFERENCE.md) - Full type documentation
- [Architecture](ARCHITECTURE.md) - System design overview
