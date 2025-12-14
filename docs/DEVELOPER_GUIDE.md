# Developer Guide

This guide covers development setup, coding conventions, and contribution guidelines for Strength Tracker.

## Table of Contents

- [Development Setup](#development-setup)
- [Project Configuration](#project-configuration)
- [Coding Conventions](#coding-conventions)
- [Testing](#testing)
- [Debugging](#debugging)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)

---

## Development Setup

### Requirements

| Requirement | Minimum Version |
|-------------|-----------------|
| macOS | 14.0 (Sonoma) |
| Xcode | 15.0 |
| iOS Target | 17.0 |
| Swift | 5.9 |

### Getting Started

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/strength-tracker.git
   cd strength-tracker
   ```

2. **Open the project**

   ```bash
   open StrengthTracker/StrengthTracker.xcodeproj
   ```

3. **Select target**
   - Choose iPhone 15 Pro (or any iOS 17+ simulator)
   - Or connect a physical device with iOS 17+

4. **Build and run** (⌘+R)

### First Run

On first launch, the app will:
1. Initialize SwiftData model container
2. Seed the exercise library (~70 exercises)
3. Show onboarding flow for new users

---

## Project Configuration

### SwiftData Schema

The schema is defined in `StrengthTrackerApp.swift`:

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
```

### Adding a New Model

1. Create model file in `Models/`:

   ```swift
   @Model
   final class NewEntity {
       var id: UUID
       var name: String
       
       init(name: String) {
           self.id = UUID()
           self.name = name
       }
   }
   ```

2. Add to schema in `StrengthTrackerApp.swift`:

   ```swift
   let schema = Schema([
       // ... existing models
       NewEntity.self
   ])
   ```

3. SwiftData will auto-migrate on next launch

### API Keys

API keys are stored in `UserProfile` (encrypted by iOS Keychain when at rest):

```swift
profile.claudeAPIKey = "sk-ant-..."
profile.openAIAPIKey = "sk-..."
```

**Never commit API keys to source control.**

---

## Coding Conventions

### File Organization

```
Feature/
├── FeatureView.swift        # Main view
├── FeatureViewModel.swift   # View model (if needed)
├── FeatureSubview.swift     # Subcomponents
└── FeatureModels.swift      # Feature-specific types
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Views | PascalCase + View | `WorkoutView` |
| View Models | PascalCase + ViewModel | `WorkoutViewModel` |
| Models | PascalCase | `WorkoutTemplate` |
| Functions | camelCase | `startWorkout()` |
| Properties | camelCase | `currentExercise` |
| Constants | camelCase | `defaultRestTime` |
| Enums | PascalCase (type), camelCase (cases) | `SetType.topSet` |

### SwiftUI Patterns

**View Structure:**

```swift
struct ExampleView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Queries
    @Query private var items: [Item]
    
    // MARK: - State
    @State private var showSheet = false
    @State private var selectedItem: Item?
    
    // MARK: - Properties
    let inputData: InputType
    
    // MARK: - Computed Properties
    private var filteredItems: [Item] {
        items.filter { ... }
    }
    
    // MARK: - Body
    var body: some View {
        content
            .sheet(isPresented: $showSheet) { ... }
    }
    
    // MARK: - View Builders
    @ViewBuilder
    private var content: some View {
        // Main content
    }
    
    // MARK: - Actions
    private func handleAction() {
        // Action logic
    }
}
```

### SwiftData Patterns

**Creating entities:**

```swift
let template = WorkoutTemplate(name: "New Workout", dayNumber: 1)
modelContext.insert(template)
try? modelContext.save()
```

**Deleting entities:**

```swift
modelContext.delete(template)
try? modelContext.save()
```

**Querying:**

```swift
// Declarative (preferred)
@Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]

// Imperative (when needed)
let descriptor = FetchDescriptor<Exercise>(
    predicate: #Predicate { $0.movementPattern == .squat }
)
let exercises = try? modelContext.fetch(descriptor)
```

---

## Testing

### Running Tests

```bash
# Unit tests
xcodebuild test -scheme StrengthTracker -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or in Xcode: ⌘+U
```

### Test Structure

```
StrengthTrackerTests/
├── Models/
│   ├── PrescriptionTests.swift
│   └── E1RMCalculatorTests.swift
├── Agent/
│   ├── OfflineEngineTests.swift
│   └── ProgressionRulesTests.swift
└── Views/
    └── WorkoutViewModelTests.swift
```

### Testing SwiftData

```swift
func testExerciseCreation() throws {
    let container = try ModelContainer(
        for: Exercise.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    
    let exercise = Exercise(name: "Test", movementPattern: .squat, ...)
    context.insert(exercise)
    
    let descriptor = FetchDescriptor<Exercise>()
    let exercises = try context.fetch(descriptor)
    
    XCTAssertEqual(exercises.count, 1)
    XCTAssertEqual(exercises.first?.name, "Test")
}
```

### Testing Agent Logic

```swift
func testProgressionIncrease() async {
    let engine = OfflineProgressionEngine()
    
    let context = CoachContext(
        userGoal: "Strength",
        currentTemplate: TemplateContext(name: "Test", exercises: [
            TemplateExerciseContext(
                name: "Bench Press",
                prescription: PrescriptionContext(
                    progressionType: "Top Set + Backoffs",
                    topSetRepsRange: "4-6",
                    topSetRPECap: 8.0,
                    ...
                ),
                isOptional: false
            )
        ]),
        recentHistory: [
            ExerciseHistoryContext(
                exerciseName: "Bench Press",
                lastSessions: [
                    SessionHistoryContext(
                        date: "2024-01-15",
                        topSetWeight: 100.0,
                        topSetReps: 6,  // Hit max reps
                        topSetRPE: 8.0, // At cap
                        totalSets: 4,
                        e1RM: 120.0
                    )
                ]
            )
        ],
        ...
    )
    
    let plan = await engine.generatePlan(context: context)
    
    // Should increase weight
    XCTAssertEqual(plan.exercises.first?.topSet?.weight, 102.5)
}
```

---

## Debugging

### Console Logging

```swift
// Debug logging (remove in production)
print("🏋️ Starting workout: \(template.name)")
print("🏋️ Template has \(template.exercises.count) exercises")
```

### SwiftData Debugging

Enable SQL logging:

```swift
// In scheme arguments
-com.apple.CoreData.SQLDebug 1
```

### Network Debugging

For LLM API calls:

```swift
// In ClaudeProvider/OpenAIProvider
print("📤 Request: \(userMessage)")
print("📥 Response: \(content)")
```

### Common Debug Points

| Issue | Debug Location |
|-------|---------------|
| Empty templates | `seedDataIfNeeded()` in App |
| Workout not starting | `startWorkout()` in HomeView |
| Plan generation failing | `LLMService.generatePlan()` |
| Sets not saving | `saveWorkout()` in WorkoutView |

---

## Common Tasks

### Adding a New Exercise

1. Add to `ExerciseLibrary.swift`:

   ```swift
   exercises.append(Exercise(
       name: "New Exercise",
       movementPattern: .horizontalPush,
       primaryMuscles: [.chest],
       secondaryMuscles: [.triceps],
       equipmentRequired: [.barbell, .bench],
       isCompound: true,
       defaultProgressionType: .topSetBackoff
   ))
   ```

2. The exercise will be available after app reinstall or when seeding runs

### Adding a New Enum Case

1. Add to enum in `Models/Enums/`:

   ```swift
   enum MovementPattern: String, Codable, CaseIterable {
       // ... existing cases
       case newPattern = "New Pattern"
   }
   ```

2. Handle in UI where used:

   ```swift
   switch pattern {
   case .newPattern:
       // Handle new case
   }
   ```

### Adding a New View

1. Create file in appropriate `Views/` subdirectory
2. Add to navigation if needed
3. Connect to data via `@Query` or props

### Adding a New LLM Provider

1. Create `NewProvider.swift` in `Agent/`:

   ```swift
   class NewProvider: LLMProvider {
       let providerType: LLMProviderType = .new
       
       func generatePlan(context: CoachContext) async throws -> TodayPlanResponse {
           // Implementation
       }
       
       // ... other methods
   }
   ```

2. Add case to `LLMProviderType` enum

3. Add to `LLMService`:

   ```swift
   private var newProvider: NewProvider?
   
   func getProvider(for type: LLMProviderType) -> LLMProvider? {
       switch type {
       case .new: return newProvider
       // ...
       }
   }
   ```

---

## Troubleshooting

### Empty Templates

**Symptom:** Templates exist but have no exercises

**Cause:** Race condition during onboarding (fixed in recent update)

**Solution:**
1. Delete app from simulator
2. Rebuild and run
3. Complete onboarding again

Or the app will auto-repair on next launch via `seedDataIfNeeded()`.

### Workout Not Starting

**Symptom:** "Start Workout" button does nothing

**Check:**
1. Templates have exercises
2. `selectedTemplate` is set
3. Sheet dismissal timing (0.3s delay needed)

**Debug:**

```swift
print("🏋️ Template: \(template.name)")
print("🏋️ Exercises: \(template.exercises.count)")
print("🏋️ showActiveWorkout: \(showActiveWorkout)")
```

### LLM Not Responding

**Symptom:** Plan generation hangs or fails

**Check:**
1. API key is valid
2. Network connectivity
3. API rate limits

**Debug:**

```swift
// Check error in LLMService
print("❌ LLM Error: \(lastError ?? "none")")
```

### SwiftData Migration Issues

**Symptom:** App crashes on launch after model changes

**Solution:**
1. Delete app data (simulator: Erase All Content and Settings)
2. Rebuild

For production, implement proper migration:

```swift
let schema = Schema([...])
let migration = MigrationPlan(...)
let container = try ModelContainer(for: schema, migrationPlan: migration)
```

### UI Not Updating

**Symptom:** Data changes but view doesn't reflect

**Check:**
1. Using `@Query` for reactive data
2. Changes saved with `modelContext.save()`
3. State properties using `@State` or `@Published`

---

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Claude API Documentation](https://docs.anthropic.com/)
- [OpenAI API Documentation](https://platform.openai.com/docs)

---

## See Also

- [Architecture](ARCHITECTURE.md) - System design
- [Data Models](DATA_MODELS.md) - Entity details
- [Agent System](AGENT_SYSTEM.md) - AI coaching
- [Views](VIEWS.md) - UI structure
