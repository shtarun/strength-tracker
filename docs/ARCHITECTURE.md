# Architecture

This document describes the overall architecture of the Strength Tracker iOS app, including design patterns, component relationships, and data flow.

## Table of Contents

- [Overview](#overview)
- [Design Patterns](#design-patterns)
- [Layer Architecture](#layer-architecture)
- [Component Diagram](#component-diagram)
- [Data Flow](#data-flow)
- [Dependency Graph](#dependency-graph)

---

## Overview

Strength Tracker follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│                   (SwiftUI Views)                        │
├─────────────────────────────────────────────────────────┤
│                    Business Layer                        │
│          (ViewModels, Services, Agent System)            │
├─────────────────────────────────────────────────────────┤
│                      Data Layer                          │
│                (SwiftData Models)                        │
├─────────────────────────────────────────────────────────┤
│                    External Layer                        │
│              (LLM APIs, File System)                     │
└─────────────────────────────────────────────────────────┘
```

## Design Patterns

### MVVM (Model-View-ViewModel)

The app uses **MVVM** for UI architecture, leveraging SwiftUI's declarative nature:

```swift
// Model - SwiftData entity
@Model
final class WorkoutTemplate {
    var name: String
    var exercises: [ExerciseTemplate]
}

// View - SwiftUI
struct TemplatesView: View {
    @Query private var templates: [WorkoutTemplate]
    
    var body: some View {
        List(templates) { template in
            TemplateRow(template: template)
        }
    }
}
```

### Repository Pattern (via SwiftData)

SwiftData's `@Query` and `ModelContext` serve as the repository layer:

```swift
// Automatic query updates
@Query(sort: \WorkoutSession.date, order: .reverse) 
private var sessions: [WorkoutSession]

// Manual CRUD operations
modelContext.insert(newSession)
modelContext.delete(session)
try? modelContext.save()
```

### Service Pattern

Business logic is encapsulated in service classes:

| Service | Responsibility |
|---------|---------------|
| `LLMService` | Manages AI providers, plan generation |
| `ExerciseLibrary` | Seeds and manages exercise database |
| `TemplateGenerator` | Creates default workout templates |
| `SubstitutionGraph` | Maps exercise alternatives |

### Actor Pattern

Thread-safe services use Swift's `actor` for concurrency:

```swift
actor OfflineProgressionEngine {
    func generatePlan(context: CoachContext) async -> TodayPlanResponse
}
```

### Protocol-Oriented Design

AI providers conform to a common protocol:

```swift
protocol LLMProvider {
    var providerType: LLMProviderType { get }
    func generatePlan(context: CoachContext) async throws -> TodayPlanResponse
    func generateInsight(session: SessionSummary) async throws -> InsightResponse
    func analyzeStall(context: StallContext) async throws -> StallAnalysisResponse
}
```

---

## Layer Architecture

### Presentation Layer

**Location:** `Views/`

SwiftUI views organized by feature:

```
Views/
├── Home/           # Dashboard, readiness check
├── Workout/        # Active workout logging
├── Templates/      # Template CRUD
├── Progress/       # Charts, history
├── Profile/        # Settings
├── Onboarding/     # First-run flow
├── Exercise/       # Exercise details
└── Components/     # Reusable UI elements
```

**Key Characteristics:**
- Declarative UI with SwiftUI
- State managed via `@State`, `@Binding`, `@Query`
- Navigation via `NavigationStack`, sheets, full-screen covers

### Business Layer

**Location:** `Agent/`, `Services/`, `ViewModels/`

#### Agent System

The AI coaching brain:

```
Agent/
├── LLMService.swift              # Provider manager (singleton)
├── ClaudeProvider.swift          # Anthropic Claude integration
├── OpenAIProvider.swift          # OpenAI GPT integration
└── OfflineProgressionEngine.swift # Rule-based fallback
```

#### Services

Reusable business logic:

```
Services/
├── ExerciseLibrary.swift     # Exercise database seeding
├── TemplateGenerator.swift   # Default template creation
└── SubstitutionGraph.swift   # Exercise swap mappings
```

### Data Layer

**Location:** `Models/`

SwiftData entities with relationships:

```
Models/
├── UserProfile.swift        # User settings
├── EquipmentProfile.swift   # Available equipment
├── Exercise.swift           # Exercise library
├── WorkoutTemplate.swift    # Program templates
├── ExerciseTemplate.swift   # Template-exercise link
├── WorkoutSession.swift     # Logged workouts
├── WorkoutSet.swift         # Individual sets
├── PainFlag.swift           # Injury tracking
└── Enums/                   # Supporting types
```

### External Layer

External integrations:

| Integration | Purpose |
|-------------|---------|
| Claude API | AI workout planning via Anthropic |
| OpenAI API | Alternative AI provider |
| SwiftData Store | Local SQLite persistence |

---

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                              App                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    StrengthTrackerApp                        │   │
│  │                    ModelContainer                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                       │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      ContentView                             │   │
│  │              ┌───────────────┬───────────────┐              │   │
│  │              ▼               ▼               ▼              │   │
│  │      OnboardingFlow    MainTabView                          │   │
│  │                        ┌─────┴─────┐                        │   │
│  │                        ▼     ▼     ▼                        │   │
│  │                   HomeView Templates Progress Profile       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                       │
│         ┌────────────────────┼────────────────────┐                 │
│         ▼                    ▼                    ▼                 │
│  ┌─────────────┐    ┌───────────────┐    ┌──────────────┐         │
│  │ LLMService  │    │ ExerciseLib   │    │ TemplateGen  │         │
│  │             │    │               │    │              │         │
│  │ ┌─────────┐ │    └───────────────┘    └──────────────┘         │
│  │ │ Claude  │ │                                                    │
│  │ │ OpenAI  │ │                                                    │
│  │ │ Offline │ │                                                    │
│  │ └─────────┘ │                                                    │
│  └─────────────┘                                                    │
│         │                                                            │
│         ▼                                                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     SwiftData Store                          │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │   │
│  │  │UserProf  │ │ Exercise │ │ Template │ │ Session  │       │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Workout Start Flow

```
User taps "Start Workout"
         │
         ▼
┌─────────────────────┐
│  ReadinessCheck     │ ◄── User inputs energy, soreness, time
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│  startWorkout()     │
│  - Create session   │
│  - Build context    │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐     ┌─────────────────────┐
│  LLMService         │────►│  LLM Provider       │
│  generatePlan()     │     │  (Claude/OpenAI)    │
└─────────────────────┘     └─────────────────────┘
         │                            │
         │◄───────────────────────────┘
         │    TodayPlanResponse
         ▼
┌─────────────────────┐
│  WorkoutView        │
│  - Display sets     │
│  - Log completion   │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│  SwiftData          │
│  - Save WorkoutSet  │
│  - Save Session     │
└─────────────────────┘
```

### AI Plan Generation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      CoachContext                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Template    │  │ Readiness   │  │ History     │         │
│  │ exercises   │  │ energy      │  │ last sets   │         │
│  │ prescription│  │ soreness    │  │ e1RM        │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │      LLM Provider       │
              │  ┌───────────────────┐  │
              │  │ System Prompt     │  │
              │  │ - Coaching rules  │  │
              │  │ - RPE guidelines  │  │
              │  │ - Progression     │  │
              │  └───────────────────┘  │
              │  ┌───────────────────┐  │
              │  │ User Prompt       │  │
              │  │ - Context JSON    │  │
              │  │ - Output schema   │  │
              │  └───────────────────┘  │
              └─────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   TodayPlanResponse                          │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ exercises[]     │  │ adjustments[]   │                   │
│  │ - warmupSets    │  │ - "Reduced RPE" │                   │
│  │ - topSet        │  │                 │                   │
│  │ - backoffSets   │  │ reasoning[]     │                   │
│  │ - workingSets   │  │ - "Last 80kg×6" │                   │
│  └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Dependency Graph

### Module Dependencies

```
         StrengthTrackerApp
                 │
         ┌───────┴───────┐
         ▼               ▼
    ContentView      ModelContainer
         │               │
    ┌────┴────┐         │
    ▼         ▼         │
 MainTab  Onboarding    │
    │         │         │
    ▼         ▼         ▼
┌───────────────────────────────┐
│           Views               │
│  (Home, Workout, Templates,   │
│   Progress, Profile)          │
└───────────────────────────────┘
         │
    ┌────┴────────────────┐
    ▼                     ▼
┌──────────┐      ┌──────────────┐
│ Services │      │    Agent     │
│          │      │              │
│ Exercise │      │ LLMService   │
│ Library  │◄────►│              │
│          │      │ ┌──────────┐ │
│ Template │      │ │Providers │ │
│ Generator│      │ └──────────┘ │
└──────────┘      └──────────────┘
         │               │
         └───────┬───────┘
                 ▼
         ┌───────────────┐
         │    Models     │
         │  (SwiftData)  │
         └───────────────┘
```

### Key Relationships

| Component | Depends On | Depended By |
|-----------|-----------|-------------|
| `LLMService` | `LLMProvider` protocol, `OfflineEngine` | Views, Services |
| `ExerciseLibrary` | `Exercise` model | `TemplateGenerator`, App startup |
| `TemplateGenerator` | `ExerciseLibrary`, Models | Onboarding, App startup |
| Views | Models (via `@Query`), Services | - |
| Models | - | Everything |

---

## Threading Model

### Main Actor

Most UI and data operations run on `@MainActor`:

```swift
@MainActor
class LLMService: ObservableObject { }

@MainActor
class ExerciseLibrary { }
```

### Actor Isolation

CPU-intensive work uses Swift actors:

```swift
actor OfflineProgressionEngine {
    func generatePlan(context: CoachContext) async -> TodayPlanResponse
}
```

### Async/Await

Network calls and long operations use structured concurrency:

```swift
Task {
    isGeneratingPlan = true
    let plan = try await LLMService.shared.generatePlan(context: context)
    showActiveWorkout = true
}
```

---

## Error Handling

### LLM Errors

```swift
enum LLMError: Error {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContent
    case decodingError(String)
}
```

### Fallback Strategy

When LLM fails, the app gracefully degrades:

```swift
func generatePlan(...) async throws -> TodayPlanResponse {
    if let llmProvider = getProvider(for: provider) {
        do {
            return try await llmProvider.generatePlan(context: context)
        } catch {
            lastError = "LLM unavailable, using offline mode"
            // Fall through to offline
        }
    }
    
    // Offline fallback - always works
    return await offlineEngine.generatePlan(context: context)
}
```

---

## See Also

- [Data Models](DATA_MODELS.md) - Entity details and relationships
- [Agent System](AGENT_SYSTEM.md) - AI coaching deep dive
- [Views](VIEWS.md) - UI structure and navigation
