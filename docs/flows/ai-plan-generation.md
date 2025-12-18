# AI Workout Plan Generation Flow

This document describes the complete user flow for generating workout plans using AI.

## Overview

The AI Plan Generator is a 5-step wizard that collects user preferences and generates a personalized multi-week workout program.

## Flow Diagram

```mermaid
flowchart TD
    subgraph User["👤 User Actions"]
        A[Open Templates Tab] --> B[Tap 'Plans' Section]
        B --> C[Tap '+' Button]
        C --> D{Choose Creation Method}
        D -->|AI Generated| E[Launch AI Wizard]
        D -->|Manual| M[Create Plan Sheet]
        D -->|From Template| T[Template Browser]
    end

    subgraph Wizard["🧙 AI Plan Wizard"]
        E --> W1[Step 1: Duration & Frequency]
        W1 --> W2[Step 2: Goal Selection]
        W2 --> W3[Step 3: Split Type]
        W3 --> W4[Step 4: Focus Areas - Optional]
        W4 --> W5[Step 5: Review & Generate]
    end

    subgraph Generation["🤖 AI Generation"]
        W5 --> G1[Collect User Profile]
        G1 --> G2[Build LLM Request]
        G2 --> G3{Select Provider}
        G3 -->|Claude| G4A[Claude API Call]
        G3 -->|OpenAI| G4B[OpenAI API Call]
        G4A --> G5[Parse JSON Response]
        G4B --> G5
        G5 --> G6{Valid Response?}
        G6 -->|No| G7[Show Error]
        G7 --> W5
        G6 -->|Yes| G8[Display Preview]
    end

    subgraph Saving["💾 Save Plan"]
        G8 --> S1{User Approves?}
        S1 -->|No| S2[Edit or Regenerate]
        S2 --> W5
        S1 -->|Yes| S3[Create WorkoutPlan Model]
        S3 --> S4[Create PlanWeek Models]
        S4 --> S5[Create WorkoutTemplate Models]
        S5 --> S6[Link Templates to Weeks]
        S6 --> S7[Save to SwiftData]
        S7 --> S8[Navigate to Plan Detail]
    end

    style E fill:#4CAF50,color:white
    style G3 fill:#2196F3,color:white
    style G8 fill:#FF9800,color:white
    style S7 fill:#9C27B0,color:white
```

## Step Details

### Step 1: Duration & Frequency

```mermaid
flowchart LR
    subgraph Input["User Input"]
        A[Select Duration] --> B[4-16 weeks]
        C[Select Days/Week] --> D[2-6 days]
        E[Toggle Deload Weeks] --> F[Yes/No]
    end
    
    subgraph Defaults["Defaults"]
        G[Duration: 8 weeks]
        H[Days: 4 per week]
        I[Deload: Enabled]
    end
```

### Step 2: Goal Selection

```mermaid
flowchart TD
    A[Goal Selection] --> B{Choose Goal}
    B --> C[💪 Strength<br/>Lower reps, heavier weights]
    B --> D[📈 Hypertrophy<br/>Moderate reps, muscle growth]
    B --> E[⚖️ Both<br/>Balanced approach]
```

### Step 3: Split Selection

```mermaid
flowchart TD
    A[Split Selection] --> B{Choose Split}
    B --> C[Full Body<br/>2-3x per week]
    B --> D[Upper/Lower<br/>4x per week]
    B --> E[Push/Pull/Legs<br/>6x per week]
    B --> F[Bro Split<br/>5-6x per week]
```

### Step 4: Focus Areas (Optional)

```mermaid
flowchart TD
    A[Focus Areas] --> B[Primary Muscles]
    A --> C[Secondary Muscles]
    
    B --> B1[Chest]
    B --> B2[Back]
    B --> B3[Shoulders]
    B --> B4[Quads]
    B --> B5[Hamstrings]
    B --> B6[Glutes]
    
    C --> C1[Biceps]
    C --> C2[Triceps]
    C --> C3[Calves]
    C --> C4[Core]
```

## LLM Request Structure

```mermaid
classDiagram
    class GeneratePlanRequest {
        +Goal goal
        +Int durationWeeks
        +Int daysPerWeek
        +Split split
        +Equipment[] equipment
        +Bool includeDeloads
        +Muscle[]? focusAreas
    }
    
    class GeneratedPlanResponse {
        +String planName
        +String description
        +GeneratedWeek[] weeks
        +String coachingNotes
    }
    
    class GeneratedWeek {
        +Int weekNumber
        +String weekType
        +GeneratedWorkout[] workouts
        +String? weekNotes
    }
    
    class GeneratedWorkout {
        +Int dayNumber
        +String name
        +GeneratedExercise[] exercises
        +Int targetDuration
    }
    
    GeneratePlanRequest --> GeneratedPlanResponse : generates
    GeneratedPlanResponse --> GeneratedWeek : contains
    GeneratedWeek --> GeneratedWorkout : contains
```

## Error Handling

```mermaid
flowchart TD
    A[API Call] --> B{Response Status}
    B -->|Success| C[Parse JSON]
    B -->|Rate Limited| D[Show Rate Limit Message]
    B -->|Network Error| E[Show Network Error]
    B -->|Auth Error| F[Show API Key Error]
    
    C --> G{Valid JSON?}
    G -->|Yes| H[Create Preview]
    G -->|No| I[Show Parse Error]
    
    D --> J[Retry Option]
    E --> J
    F --> K[Settings Link]
    I --> J
```

## Data Model Creation

```mermaid
sequenceDiagram
    participant User
    participant View as AIPlanGeneratorSheet
    participant Service as LLMService
    participant Provider as Claude/OpenAI
    participant DB as SwiftData

    User->>View: Tap "Generate Plan"
    View->>Service: generateWorkoutPlan(request)
    Service->>Provider: API Request
    Provider-->>Service: JSON Response
    Service-->>View: GeneratedPlanResponse
    
    User->>View: Tap "Save Plan"
    View->>DB: Create WorkoutPlan
    View->>DB: Create PlanWeeks
    View->>DB: Create WorkoutTemplates
    View->>DB: Create ExerciseTemplates
    DB-->>View: Confirmation
    View->>User: Navigate to Plan Detail
```
