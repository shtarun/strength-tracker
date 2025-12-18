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
    PainFlag.self
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
