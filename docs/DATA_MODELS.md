# Data Models

This document details the SwiftData entities, their properties, relationships, and usage patterns in Strength Tracker.

## Table of Contents

- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Core Entities](#core-entities)
  - [UserProfile](#userprofile)
  - [EquipmentProfile](#equipmentprofile)
  - [Exercise](#exercise)
  - [WorkoutTemplate](#workouttemplate)
  - [ExerciseTemplate](#exercisetemplate)
  - [WorkoutSession](#workoutsession)
  - [WorkoutSet](#workoutset)
  - [PainFlag](#painflag)
  - [WorkoutPlan](#workoutplan)
  - [PlanWeek](#planweek)
- [Plan Templates](#plan-templates)
- [Supporting Types](#supporting-types)
- [Enumerations](#enumerations)
- [SwiftData Configuration](#swiftdata-configuration)

---

## Entity Relationship Diagram

```
┌─────────────────┐         ┌─────────────────────┐
│   UserProfile   │────────►│  EquipmentProfile   │
│                 │  1:1    │                     │
└─────────────────┘         └─────────────────────┘

┌─────────────────┐         ┌─────────────────────┐
│ WorkoutTemplate │◄───────►│  ExerciseTemplate   │
│                 │  1:N    │                     │
└─────────────────┘         └──────────┬──────────┘
                                       │
                                       │ N:1
                                       ▼
                            ┌─────────────────────┐
                            │      Exercise       │
                            │                     │
                            └─────────────────────┘
                                       ▲
                                       │ N:1
                                       │
┌─────────────────┐         ┌──────────┴──────────┐
│  WorkoutSession │◄───────►│    WorkoutSet       │
│                 │  1:N    │                     │
└────────┬────────┘         └─────────────────────┘
         │
         │ N:1
         ▼
┌─────────────────┐
│ WorkoutTemplate │
│   (optional)    │
└─────────────────┘

┌─────────────────┐
│    PainFlag     │────────► Exercise (optional)
└─────────────────┘
```

---

## Core Entities

### UserProfile

The main user entity storing preferences and settings.

**File:** `Models/UserProfile.swift`

```swift
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var goal: Goal                        // .strength, .hypertrophy, .both
    var daysPerWeek: Int                  // 2-6
    var preferredSplit: Split             // .upperLower, .ppl, .fullBody, .custom
    var rpeFamiliarity: Bool              // Show RPE inputs?
    var defaultRestTime: Int              // Seconds (90, 120, 180, 240)
    var unitSystem: UnitSystem            // .metric, .imperial
    var preferredLLMProvider: LLMProviderType  // .claude, .openai, .offline
    var claudeAPIKey: String?
    var openAIAPIKey: String?
    var appearanceMode: AppearanceMode    // .auto, .light, .dark
    var showYouTubeLinks: Bool            // Show YouTube form video links
    var activeDaysGoal: Int               // Weekly workout goal (1-7)
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) 
    var equipmentProfile: EquipmentProfile?
}
```

**Computed Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `activeAPIKey` | `String?` | Returns API key for selected provider |
| `hasValidAPIKey` | `Bool` | Validates API key availability |

**Relationships:**

| Relationship | Type | Delete Rule |
|--------------|------|-------------|
| `equipmentProfile` | `EquipmentProfile?` | Cascade |

---

### EquipmentProfile

Tracks user's available training equipment.

**File:** `Models/EquipmentProfile.swift`

```swift
@Model
final class EquipmentProfile {
    var id: UUID
    var location: Location                // .gym, .home
    var hasAdjustableDumbbells: Bool
    var hasBarbell: Bool
    var hasRack: Bool
    var hasCables: Bool
    var hasPullUpBar: Bool
    var hasBands: Bool
    var hasBench: Bool
    var hasMachines: Bool
    var availablePlatesData: Data?        // Encoded [Double]
    var dumbbellIncrementsData: Data?     // Encoded [Double]
    var hasMicroplates: Bool
    var createdAt: Date
}
```

**Computed Properties:**

```swift
var availableEquipment: Set<Equipment> {
    // Returns set of Equipment enums based on boolean flags
}

var availablePlates: [Double] {
    // Decodes plate weights from Data
}

var dumbbellIncrements: [Double] {
    // Decodes dumbbell weight options from Data
}
```

**Equipment Flags to Equipment Enum Mapping:**

| Flag | Equipment |
|------|-----------|
| `hasBarbell` + `hasRack` | `.barbell`, `.rack` |
| `hasAdjustableDumbbells` | `.dumbbell` |
| `hasCables` | `.cable` |
| `hasPullUpBar` | `.pullUpBar` |
| `hasBands` | `.bands` |
| `hasBench` | `.bench` |
| `hasMachines` | `.machine` |
| Always included | `.bodyweight` |

---

### Exercise

Exercise library entries with movement classification and form guidance.

**File:** `Models/Exercise.swift`

```swift
@Model
final class Exercise {
    var id: UUID
    var name: String
    var movementPattern: MovementPattern
    var primaryMusclesData: Data?         // Encoded [Muscle]
    var secondaryMusclesData: Data?       // Encoded [Muscle]
    var equipmentRequiredData: Data?      // Encoded [Equipment]
    var isCompound: Bool
    var defaultProgressionType: ProgressionType
    var instructions: String?
    var formCuesData: Data?               // Encoded [String] - form tips
    var commonMistakesData: Data?         // Encoded [String] - mistakes to avoid
    var youtubeVideoURL: String?          // YouTube form tutorial link
    var isMobilityRoutine: Bool           // For mobility exercises
    var routineType: String?              // "pre-workout" or "post-workout"
    var durationSeconds: Int?             // For timed exercises
}
```

**Computed Properties:**

```swift
var primaryMuscles: [Muscle]
var secondaryMuscles: [Muscle]
var equipmentRequired: [Equipment]
var formCues: [String]                 // Form tips for the exercise
var commonMistakes: [String]           // Common mistakes to avoid
var allMuscles: [Muscle]               // Primary + secondary
var defaultWeightIncrement: Double     // 2.5kg barbell, 2.0kg dumbbell
var hasFormGuidance: Bool              // True if has form cues or mistakes
```

**Example Exercises:**

| Name | Pattern | Primary | Equipment | Compound |
|------|---------|---------|-----------|----------|
| Bench Press | Horizontal Push | Chest | Barbell, Bench, Rack | ✓ |
| Barbell Row | Horizontal Pull | Lats | Barbell | ✓ |
| Lateral Raise | Isolation | Side Delt | Dumbbell | ✗ |
| Leg Curl | Isolation | Hamstrings | Machine | ✗ |

---

### WorkoutTemplate

Reusable workout programs.

**File:** `Models/WorkoutTemplate.swift`

```swift
@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String                      // "Upper A", "Push Day"
    var dayNumber: Int                    // 1, 2, 3... for ordering
    var targetDuration: Int               // Minutes (30, 45, 60, 75)
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) 
    var exercises: [ExerciseTemplate]
}
```

**Computed Properties:**

```swift
var sortedExercises: [ExerciseTemplate] {
    exercises.sorted { $0.orderIndex < $1.orderIndex }
}
```

**Default Templates by Split:**

| Split | Templates |
|-------|-----------|
| Upper/Lower | Upper A, Lower A, Upper B, Lower B |
| PPL | Push, Pull, Legs |
| Full Body | Full Body A, Full Body B, Full Body C |

---

### ExerciseTemplate

Links exercises to templates with prescriptions.

**File:** `Models/WorkoutTemplate.swift`

```swift
@Model
final class ExerciseTemplate {
    var id: UUID
    var orderIndex: Int                   // Position in template
    var isOptional: Bool                  // Skip when time-constrained
    var prescriptionData: Data?           // Encoded Prescription
    
    @Relationship var exercise: Exercise?
    @Relationship(inverse: \WorkoutTemplate.exercises) 
    var template: WorkoutTemplate?
}
```

**Computed Properties:**

```swift
var prescription: Prescription {
    get { /* Decode from prescriptionData */ }
    set { /* Encode to prescriptionData */ }
}
```

---

### Prescription

Training prescription for an exercise (stored as encoded JSON in `ExerciseTemplate`).

```swift
struct Prescription: Codable, Equatable {
    var progressionType: ProgressionType  // .topSetBackoff, .doubleProgression, .straightSets
    var topSetRepsMin: Int                // e.g., 4
    var topSetRepsMax: Int                // e.g., 6
    var topSetRPECap: Double              // e.g., 8.0
    var backoffSets: Int                  // e.g., 3
    var backoffRepsMin: Int               // e.g., 6
    var backoffRepsMax: Int               // e.g., 10
    var backoffLoadDropPercent: Double    // e.g., 0.10 (10%)
    var workingSets: Int                  // For double progression
}
```

**Preset Prescriptions:**

| Preset | Progression | Top Set | Backoffs | RPE |
|--------|-------------|---------|----------|-----|
| `.default` | Top Set + Backoff | 4-6 reps | 3 × 6-10 @ -10% | 8.0 |
| `.hypertrophy` | Double Progression | 8-12 reps | None | 8.5 |
| `.strength` | Top Set + Backoff | 3-5 reps | 3 × 5-8 @ -12% | 8.0 |

---

### WorkoutSession

A completed or in-progress workout.

**File:** `Models/WorkoutSession.swift`

```swift
@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var location: Location
    var readinessData: Data?              // Encoded Readiness
    var plannedDuration: Int              // Minutes
    var actualDuration: Int?              // Minutes
    var notes: String?
    var isCompleted: Bool
    var createdAt: Date
    
    @Relationship var template: WorkoutTemplate?
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
}

**Note on Relationships:**
The `template` relationship is optional. Logic must handle cases where a template is deleted but the historical session remains (preventing "invalidated model" crashes).

```

**Computed Properties:**

```swift
var readiness: Readiness {
    get { /* Decode from readinessData */ }
    set { /* Encode to readinessData */ }
}

var totalVolume: Double {
    sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
}

var formattedDuration: String
```

---

### WorkoutSet

Individual set logged during a workout.

**File:** `Models/WorkoutSet.swift`

```swift
@Model
final class WorkoutSet {
    var id: UUID
    var setType: SetType                  // .warmup, .topSet, .backoff, .working
    var weight: Double                    // kg or lbs
    var reps: Int
    var targetReps: Int
    var rpe: Double?                      // 1-10 scale
    var targetRPE: Double?
    var isCompleted: Bool
    var notes: String?
    var orderIndex: Int
    var timestamp: Date
    
    @Relationship var exercise: Exercise?
    @Relationship(inverse: \WorkoutSession.sets) var session: WorkoutSession?
}
```

**Computed Properties:**

```swift
var estimatedOneRepMax: Double {
    E1RMCalculator.epley(weight: weight, reps: reps)
}

var hitTarget: Bool {
    reps >= targetReps && (rpe ?? 10) <= (targetRPE ?? 10)
}
```

---

### PainFlag

Tracks pain/discomfort for injury management.

**File:** `Models/PainFlag.swift`

```swift
@Model
final class PainFlag {
    var id: UUID
    var bodyPart: String                  // "Lower Back", "Right Shoulder"
    var severity: PainSeverity            // .mild, .moderate, .severe
    var notes: String?
    var isResolved: Bool
    var createdAt: Date
    var resolvedAt: Date?
    
    @Relationship var exercise: Exercise?
}
```

**Usage:**

- Pain flags are considered during exercise substitution
- Severe flags → automatic exercise swap
- Moderate flags → warning shown
- Resolved flags → no longer affect planning

---

### WorkoutPlan

Multi-week training programs with periodization.

**File:** `Models/WorkoutPlan.swift`

```swift
@Model
final class WorkoutPlan {
    var id: UUID
    var name: String
    var planDescription: String?
    var durationWeeks: Int                 // 4, 6, 8, 12
    var currentWeek: Int                   // 1-based
    var isActive: Bool
    var startDate: Date?
    var workoutsPerWeek: Int               // 3-6
    var completedWorkoutsThisWeek: Int
    var goalRaw: String                    // Encoded Goal
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var weeks: [PlanWeek]
}
```

**Computed Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `goal` | `Goal` | Decoded training goal |
| `statusText` | `String` | "Week 3 of 8" or "Not started" |
| `progressPercentage` | `Double` | 0.0-1.0 completion progress |
| `currentPlanWeek` | `PlanWeek?` | Current week object |
| `isCompleted` | `Bool` | All weeks completed |
| `sortedWeeks` | `[PlanWeek]` | Weeks sorted by number |

**Key Methods:**

```swift
func recordCompletedWorkout()    // Increment progress, auto-advance week
func advanceWeekIfNeeded()       // Move to next week when complete
func activate(in context:)       // Activate plan, deactivate others
```

---

### PlanWeek

Individual week within a workout plan with modifiers.

**File:** `Models/PlanWeek.swift`

```swift
@Model
final class PlanWeek {
    var id: UUID
    var weekNumber: Int
    var weekTypeRaw: String                // Encoded WeekType
    var intensityModifier: Double          // 0.6-1.05
    var volumeModifier: Double             // 0.3-1.0
    var notes: String?
    var isCompleted: Bool

    @Relationship var templates: [WorkoutTemplate]
    @Relationship(inverse: \WorkoutPlan.weeks) var plan: WorkoutPlan?
}
```

**Week Types and Modifiers:**

| WeekType | Intensity | Volume | RPE Cap | Description |
|----------|-----------|--------|---------|-------------|
| `.regular` | 100% | 100% | 10 | Normal training |
| `.deload` | 60% | 50% | 7 | Recovery week |
| `.peak` | 105% | 70% | 9.5 | Overreaching |
| `.test` | 100% | 30% | 10 | Max testing |

**Computed Properties:**

```swift
var weekType: WeekType         // Decoded from weekTypeRaw
var weekLabel: String          // "Week 1", "Week 2", etc.
var sortedTemplates: [WorkoutTemplate]
var summaryText: String        // "3 workouts" or "No workouts assigned"

func adjustedWeight(baseWeight:) -> Double  // Apply intensity modifier
func applyModifiers(to prescription:) -> Prescription  // Adjust prescription
```

---

## Plan Templates

Pre-built workout plan templates with full exercise definitions.

**File:** `Services/PlanTemplateLibrary.swift`

### PlanTemplate

Static template for creating workout plans.

```swift
struct PlanTemplate: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let durationWeeks: Int
    let workoutsPerWeek: Int
    let goal: Goal
    let split: Split
    let weekStructure: [WeekDefinition]
    let workoutNames: [String]
    let workoutExercises: [WorkoutExerciseDefinition]
}
```

### Available Templates

| Template | Duration | Frequency | Split | Goal |
|----------|----------|-----------|-------|------|
| **Beginner Strength** | 8 weeks | 3x/week | Full Body | Strength |
| **Hypertrophy Block** | 6 weeks | 4x/week | Upper/Lower | Hypertrophy |
| **PPL Power Builder** | 8 weeks | 6x/week | Push/Pull/Legs | Both |
| **Strength Peaking** | 4 weeks | 4x/week | Upper/Lower | Strength |
| **12-Week Transform** | 12 weeks | 4x/week | Upper/Lower | Both |

### Template Exercise Structure

Each template includes complete exercise definitions:

```swift
struct WorkoutExerciseDefinition {
    let workoutName: String              // "Upper A", "Push", etc.
    let exercises: [ExerciseDefinition]
}

struct ExerciseDefinition {
    let name: String                     // "Bench Press"
    let sets: Int                        // 4
    let repsMin: Int                     // 6
    let repsMax: Int                     // 8
    let rpe: Double                      // 8.0
    let isOptional: Bool                 // false
}
```

### Example: Beginner Strength Template

**Full Body A (Squat Focus):**
| Exercise | Sets | Reps | RPE |
|----------|------|------|-----|
| Barbell Squat | 3 | 5 | 7 |
| Bench Press | 3 | 5 | 7 |
| Barbell Row | 3 | 5-8 | 7 |
| Dumbbell Shoulder Press | 2 | 8-10 | 7 |
| Plank | 3 | 30s | 6 |

**Full Body B (Deadlift Focus):**
| Exercise | Sets | Reps | RPE |
|----------|------|------|-----|
| Deadlift | 3 | 5 | 7 |
| Overhead Press | 3 | 5 | 7 |
| Lat Pulldown | 3 | 8-10 | 7 |
| Leg Press | 3 | 8-10 | 7 |
| Dumbbell Curl | 2 | 10-12 | 7 |

### Creating Plans from Templates

```swift
// New method with exercise definitions
let plan = PlanTemplateLibrary.createPlan(
    from: template,
    exercises: exercises,        // Exercise library for matching
    in: modelContext
)

// Creates:
// - WorkoutPlan with all weeks
// - WorkoutTemplate for each workout
// - ExerciseTemplate for each exercise with prescriptions
// - Uses ExerciseMatcher for fuzzy name matching
```

### Exercise Matching

The `ExerciseMatcher` utility provides fuzzy matching for exercise names:

```swift
ExerciseMatcher.findBestMatch(name: "Barbell Bench Press", in: exercises)
// Returns: Exercise with name "Bench Press"
```

**Matching Priority:**
1. Exact match
2. Contains match ("Barbell Bench Press" contains "Bench Press")
3. Reverse contains match
4. Word-based matching (most common words)
5. Prefix stripping ("barbell", "dumbbell", etc.)
6. Synonym matching ("OHP" → "Overhead Press")

---

## Supporting Types

### Readiness

User's pre-workout state (encoded in `WorkoutSession`).

```swift
struct Readiness: Codable {
    var energy: EnergyLevel      // .low, .ok, .high
    var soreness: SorenessLevel  // .none, .mild, .high
    var timeAvailable: Int       // Minutes
}
```

**Computed Flags:**

```swift
var shouldReduceIntensity: Bool {
    energy == .low || soreness == .high
}

var shouldIncreaseIntensity: Bool {
    energy == .high && soreness == .none
}
```

---

## Enumerations

**File:** `Models/Enums/`

### Goal
```swift
enum Goal: String, Codable, CaseIterable {
    case strength = "Strength"
    case hypertrophy = "Hypertrophy"
    case both = "Both"
}
```

### Split
```swift
enum Split: String, Codable, CaseIterable {
    case upperLower = "Upper/Lower"
    case ppl = "Push/Pull/Legs"
    case fullBody = "Full Body"
    case custom = "Custom"
}
```

### MovementPattern
```swift
enum MovementPattern: String, Codable, CaseIterable, Identifiable {
    case horizontalPush = "Horizontal Push"
    case verticalPush = "Vertical Push"
    case horizontalPull = "Horizontal Pull"
    case verticalPull = "Vertical Pull"
    case squat = "Squat"
    case hinge = "Hinge"
    case lunge = "Lunge"
    case carry = "Carry"
    case isolation = "Isolation"
}
```

### Equipment
```swift
enum Equipment: String, Codable, CaseIterable {
    case barbell, dumbbell, cable, machine
    case pullUpBar, bands, bodyweight, bench, rack
}
```

### ProgressionType
```swift
enum ProgressionType: String, Codable, CaseIterable {
    case topSetBackoff = "Top Set + Backoffs"
    case doubleProgression = "Double Progression"
    case straightSets = "Straight Sets"
}
```

### SetType
```swift
enum SetType: String, Codable {
    case warmup, topSet, backoff, working
}
```

### EnergyLevel
```swift
enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case ok = "OK"
    case high = "High"
}
```

### SorenessLevel
```swift
enum SorenessLevel: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case mild = "Mild"
    case high = "High"
}
```

### Location
```swift
enum Location: String, Codable, CaseIterable {
    case gym = "Gym"
    case home = "Home"
}
```

### UnitSystem
```swift
enum UnitSystem: String, Codable, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
}
```

### LLMProviderType
```swift
enum LLMProviderType: String, Codable, CaseIterable {
    case claude = "Claude"
    case openai = "OpenAI"
    case offline = "Offline"
}
```

### WeekType
```swift
enum WeekType: String, Codable, CaseIterable {
    case regular = "regular"
    case deload = "deload"
    case peak = "peak"
    case test = "test"

    var intensityModifier: Double  // 0.6-1.05
    var volumeModifier: Double     // 0.3-1.0
    var rpeCap: Double             // 7.0-10.0
    var icon: String               // SF Symbol name
    var color: Color               // SwiftUI color
    var coachingNotes: String      // Training guidance
}
```

---

## SwiftData Configuration

### Schema Registration

**File:** `App/StrengthTrackerApp.swift`

```swift
let schema = Schema([
    UserProfile.self,
    EquipmentProfile.self,
    Exercise.self,
    ExerciseTemplate.self,
    WorkoutTemplate.self,
    WorkoutSession.self,
    WorkoutSet.self,
    PainFlag.self,
    WorkoutPlan.self,
    PlanWeek.self,
    PausedWorkout.self
])

let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false
)

modelContainer = try ModelContainer(
    for: schema,
    configurations: [modelConfiguration]
)
```

### Querying Data

```swift
// Simple query with sorting
@Query(sort: \WorkoutTemplate.dayNumber) 
private var templates: [WorkoutTemplate]

// Reverse chronological
@Query(sort: \WorkoutSession.date, order: .reverse) 
private var sessions: [WorkoutSession]

// All exercises (no filter)
@Query private var exercises: [Exercise]
```

### CRUD Operations

```swift
// Create
let template = WorkoutTemplate(name: "New Workout", dayNumber: 1)
modelContext.insert(template)

// Update (automatic via @Bindable)
template.name = "Updated Name"

// Delete
modelContext.delete(template)

// Save
try? modelContext.save()
```

---

## See Also

- [Architecture](ARCHITECTURE.md) - System design overview
- [Progression Logic](PROGRESSION.md) - Training science
- [Agent System](AGENT_SYSTEM.md) - AI coaching
