# API Reference

This document provides complete type definitions for the Agent System's request and response structures.

## Table of Contents

- [LLM Provider Protocol](#llm-provider-protocol)
- [Context Types](#context-types)
- [Response Types](#response-types)
- [Error Types](#error-types)
- [Prompt Templates](#prompt-templates)

---

## LLM Provider Protocol

### Protocol Definition

```swift
protocol LLMProvider {
    var providerType: LLMProviderType { get }
    
    func generatePlan(context: CoachContext) async throws -> TodayPlanResponse
    func generateInsight(session: SessionSummary) async throws -> InsightResponse
    func analyzeStall(context: StallContext) async throws -> StallAnalysisResponse
}
```

### Provider Types

```swift
enum LLMProviderType: String, Codable, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
    case offline = "Offline"
}
```

### Provider Implementations

| Provider | Class | API |
|----------|-------|-----|
| Claude | `ClaudeProvider` | Anthropic Messages API |
| OpenAI | `OpenAIProvider` | OpenAI Chat Completions |
| Offline | `OfflineProgressionEngine` | Local rule-based engine |

---

## Context Types

### CoachContext

Primary input for workout plan generation.

```swift
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
```

**Field Details:**

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `userGoal` | String | Training goal | `"Strength"`, `"Hypertrophy"`, `"Both"` |
| `currentTemplate` | TemplateContext | Today's workout | See below |
| `location` | String | Training location | `"Gym"`, `"Home"` |
| `readiness` | ReadinessContext | Current state | See below |
| `timeAvailable` | Int | Available minutes | `30`, `45`, `60`, `75` |
| `recentHistory` | [ExerciseHistoryContext] | Per-exercise history | See below |
| `equipmentAvailable` | [String] | Available gear | `["Barbell", "Dumbbell"]` |
| `painFlags` | [PainFlagContext] | Active injuries | See below |

---

### TemplateContext

Workout template information.

```swift
struct TemplateContext: Codable {
    let name: String
    let exercises: [TemplateExerciseContext]
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | String | Template name | `"Upper A"` |
| `exercises` | [TemplateExerciseContext] | Ordered exercises | See below |

---

### TemplateExerciseContext

Individual exercise within a template.

```swift
struct TemplateExerciseContext: Codable {
    let name: String
    let prescription: PrescriptionContext
    let isOptional: Bool
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | String | Exercise name | `"Bench Press"` |
| `prescription` | PrescriptionContext | Rep/set scheme | See below |
| `isOptional` | Bool | Skip when time-constrained | `false` |

---

### PrescriptionContext

Training prescription for an exercise.

```swift
struct PrescriptionContext: Codable {
    let progressionType: String
    let topSetRepsRange: String
    let topSetRPECap: Double
    let backoffSets: Int
    let backoffRepsRange: String
    let backoffLoadDropPercent: Double
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `progressionType` | String | Progression model | `"Top Set + Backoffs"`, `"Double Progression"` |
| `topSetRepsRange` | String | Rep range for top set | `"4-6"` |
| `topSetRPECap` | Double | Maximum RPE | `8.0` |
| `backoffSets` | Int | Number of backoff sets | `3` |
| `backoffRepsRange` | String | Rep range for backoffs | `"6-10"` |
| `backoffLoadDropPercent` | Double | Weight reduction | `0.10` (10%) |

---

### ReadinessContext

Pre-workout state.

```swift
struct ReadinessContext: Codable {
    let energy: String
    let soreness: String
}
```

| Field | Type | Values |
|-------|------|--------|
| `energy` | String | `"Low"`, `"OK"`, `"High"` |
| `soreness` | String | `"None"`, `"Mild"`, `"High"` |

---

### ExerciseHistoryContext

Recent performance history for an exercise.

```swift
struct ExerciseHistoryContext: Codable {
    let exerciseName: String
    let lastSessions: [SessionHistoryContext]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `exerciseName` | String | Exercise name |
| `lastSessions` | [SessionHistoryContext] | Last 3-5 sessions |

---

### SessionHistoryContext

Single session's performance.

```swift
struct SessionHistoryContext: Codable {
    let date: String
    let topSetWeight: Double
    let topSetReps: Int
    let topSetRPE: Double?
    let totalSets: Int
    let e1RM: Double
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `date` | String | ISO 8601 date | `"2024-01-15"` |
| `topSetWeight` | Double | Weight in kg | `100.0` |
| `topSetReps` | Int | Reps achieved | `5` |
| `topSetRPE` | Double? | RPE if recorded | `8.0` |
| `totalSets` | Int | Total working sets | `4` |
| `e1RM` | Double | Estimated 1RM | `116.7` |

---

### PainFlagContext

Active injury/pain.

```swift
struct PainFlagContext: Codable {
    let exerciseName: String?
    let bodyPart: String
    let severity: String
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `exerciseName` | String? | Triggering exercise | `"Bench Press"` |
| `bodyPart` | String | Affected area | `"Right Shoulder"` |
| `severity` | String | Pain level | `"Mild"`, `"Moderate"`, `"Severe"` |

---

### SessionSummary

Completed workout summary for insight generation.

```swift
struct SessionSummary: Codable {
    let templateName: String
    let exercises: [ExerciseSummary]
    let readiness: ReadinessContext
    let totalVolume: Double
    let duration: Int
}
```

| Field | Type | Description |
|-------|------|-------------|
| `templateName` | String | Workout name |
| `exercises` | [ExerciseSummary] | Per-exercise summary |
| `readiness` | ReadinessContext | Pre-workout state |
| `totalVolume` | Double | Total kg lifted |
| `duration` | Int | Minutes |

---

### ExerciseSummary

Single exercise summary.

```swift
struct ExerciseSummary: Codable {
    let name: String
    let topSet: SetSummary?
    let backoffSets: [SetSummary]
    let targetHit: Bool
    let e1RM: Double
    let previousE1RM: Double?
}
```

---

### SetSummary

Set performance summary.

```swift
struct SetSummary: Codable {
    let weight: Double
    let reps: Int
    let rpe: Double?
    let targetReps: Int
}
```

---

### StallContext

Context for plateau analysis.

```swift
struct StallContext: Codable {
    let exerciseName: String
    let lastSessions: [SessionHistoryContext]
    let currentPrescription: PrescriptionContext
    let userGoal: String
}
```

---

## Response Types

### TodayPlanResponse

Generated workout plan.

```swift
struct TodayPlanResponse: Codable {
    let exercises: [PlannedExerciseResponse]
    let substitutions: [SubstitutionResponse]
    let adjustments: [String]
    let reasoning: [String]
    let estimatedDuration: Int
}
```

**JSON Schema:**

```json
{
  "exercises": [
    {
      "exerciseName": "Bench Press",
      "warmupSets": [
        {"weight": 20.0, "reps": 10, "rpeCap": 5.0, "setCount": 1},
        {"weight": 60.0, "reps": 5, "rpeCap": 5.0, "setCount": 1},
        {"weight": 80.0, "reps": 3, "rpeCap": 6.0, "setCount": 1}
      ],
      "topSet": {"weight": 100.0, "reps": 5, "rpeCap": 8.0, "setCount": 1},
      "backoffSets": [
        {"weight": 90.0, "reps": 8, "rpeCap": 8.0, "setCount": 3}
      ],
      "workingSets": []
    }
  ],
  "substitutions": [],
  "adjustments": ["Reduced intensity due to low energy"],
  "reasoning": ["Bench Press: Last 100kg × 5 @ RPE 8"],
  "estimatedDuration": 55
}
```

---

### PlannedExerciseResponse

Individual exercise plan.

```swift
struct PlannedExerciseResponse: Codable {
    let exerciseName: String
    let warmupSets: [PlannedSetResponse]
    let topSet: PlannedSetResponse?
    let backoffSets: [PlannedSetResponse]
    let workingSets: [PlannedSetResponse]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `exerciseName` | String | Exercise name |
| `warmupSets` | [PlannedSetResponse] | Warmup progressions |
| `topSet` | PlannedSetResponse? | Primary working set (for top-set progressions) |
| `backoffSets` | [PlannedSetResponse] | Volume sets at reduced load |
| `workingSets` | [PlannedSetResponse] | Working sets (for double progression) |

---

### PlannedSetResponse

Set prescription.

```swift
struct PlannedSetResponse: Codable {
    let weight: Double
    let reps: Int
    let rpeCap: Double?
    let setCount: Int
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `weight` | Double | Load in kg | `100.0` |
| `reps` | Int | Target reps | `5` |
| `rpeCap` | Double? | Max RPE | `8.0` |
| `setCount` | Int | Number of sets at this spec | `3` |

---

### SubstitutionResponse

Exercise swap.

```swift
struct SubstitutionResponse: Codable {
    let from: String
    let to: String
    let reason: String
}
```

| Field | Type | Description |
|-------|------|-------------|
| `from` | String | Original exercise |
| `to` | String | Replacement exercise |
| `reason` | String | Why swapped |

**Example:**

```json
{
  "from": "Barbell Row",
  "to": "Dumbbell Row",
  "reason": "Barbell not available"
}
```

---

### InsightResponse

Post-workout feedback.

```swift
struct InsightResponse: Codable {
    let insight: String
    let action: String
    let category: String
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `insight` | String | Observation | `"Bench Press e1RM improved 3%"` |
| `action` | String | Recommendation | `"Add 2.5kg next session"` |
| `category` | String | Category | `"progress"`, `"fatigue"`, `"technique"`, `"volume"` |

---

### StallAnalysisResponse

Plateau analysis result.

```swift
struct StallAnalysisResponse: Codable {
    let isStalled: Bool
    let reason: String?
    let suggestedFix: String?
    let fixType: String?
    let details: String?
}
```

| Field | Type | Description |
|-------|------|-------------|
| `isStalled` | Bool | Whether stalled |
| `reason` | String? | Why stalled |
| `suggestedFix` | String? | Recommended action |
| `fixType` | String? | Fix category: `"deload"`, `"rep_range"`, `"variation"`, `"volume"` |
| `details` | String? | Additional info |

**Example:**

```json
{
  "isStalled": true,
  "reason": "No e1RM improvement in 3 sessions",
  "suggestedFix": "Take a micro-deload: reduce weight by 8% for one week",
  "fixType": "deload",
  "details": "New target: 92kg"
}
```

---

## Error Types

### LLMError

Errors from LLM operations.

```swift
enum LLMError: Error {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContent
    case decodingError(String)
}
```

| Case | Description |
|------|-------------|
| `invalidURL` | Malformed API URL |
| `invalidResponse` | Non-HTTP response |
| `apiError` | API returned error status |
| `noContent` | Empty response body |
| `decodingError` | JSON parsing failed |

---

## Prompt Templates

### System Prompt

```
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
```

### Plan Prompt

```
Generate today's workout plan based on the context provided.

For each exercise:
1. Calculate warmup sets (typically 3-4 sets working up to top set weight)
2. Set the top set target based on recent history and readiness
3. Calculate backoff sets (typically 8-12% lighter than top set)
4. Note any substitutions needed due to equipment or pain

Respond with valid JSON matching this schema:
{
  "exercises": [...],
  "substitutions": [...],
  "adjustments": [...],
  "reasoning": [...],
  "estimatedDuration": number
}
```

### Insight Prompt

```
Generate a single insight and actionable recommendation for this completed workout.

Focus on:
- Progress: any PRs, rep PRs, or e1RM improvements
- Fatigue: missed reps, high RPE, reduced volume
- Next steps: what to do next session

Respond with valid JSON:
{
  "insight": "string",
  "action": "string",
  "category": "progress" | "fatigue" | "technique" | "volume"
}
```

### Stall Prompt

```
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
```

---

## See Also

- [Agent System](AGENT_SYSTEM.md) - Implementation details
- [Progression Logic](PROGRESSION.md) - Training science
- [Architecture](ARCHITECTURE.md) - System design
