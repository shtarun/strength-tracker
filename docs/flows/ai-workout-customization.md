# AI Workout Customization Flow

This document describes how the AI customizes workouts based on user's daily readiness check.

## Overview

Before starting a workout, users complete a readiness check. The AI uses this information to adjust the workout plan for optimal results and injury prevention.

## Flow Diagram

```mermaid
flowchart TD
    subgraph Start["🏠 Home Screen"]
        A[User Opens App] --> B[Tap 'Start Workout']
        B --> C{Previous Readiness Check?}
        C -->|Recent < 4hrs| D[Use Cached Readiness]
        C -->|None/Expired| E[Show Readiness Sheet]
    end

    subgraph Readiness["📋 Readiness Check"]
        E --> R1[Rate Soreness<br/>1-5 Scale]
        R1 --> R2[Rate Energy<br/>1-5 Scale]
        R2 --> R3[Available Time<br/>Minutes]
        R3 --> R4[Select Injuries/Pain<br/>Optional]
        R4 --> R5{All Default Values?}
    end

    subgraph Decision["🔀 Routing Decision"]
        R5 -->|Yes| N1[Skip AI Generation]
        R5 -->|No| AI1[Trigger AI Customization]
        D --> N1
        N1 --> W1[Use Standard Template]
    end

    subgraph AIGen["🤖 AI Customization"]
        AI1 --> AI2[Collect Context]
        AI2 --> AI3[Build Prompt]
        AI3 --> AI4[Call LLM Provider]
        AI4 --> AI5[Parse Recommendations]
        AI5 --> AI6{Valid Response?}
        AI6 -->|No| AI7[Fallback to Offline Engine]
        AI6 -->|Yes| AI8[Apply Modifications]
        AI7 --> AI8
    end

    subgraph Workout["💪 Modified Workout"]
        W1 --> W2[Display Workout]
        AI8 --> W2
        W2 --> W3[Show AI Adjustments Banner]
        W3 --> W4[Begin Workout Session]
    end

    style AI1 fill:#4CAF50,color:white
    style AI4 fill:#2196F3,color:white
    style AI8 fill:#FF9800,color:white
```

## Readiness Factors

```mermaid
flowchart LR
    subgraph Inputs["Input Factors"]
        A[Soreness Level]
        B[Energy Level]
        C[Available Time]
        D[Pain/Injuries]
        E[Sleep Quality]
    end

    subgraph Impact["AI Adjustments"]
        A --> F[Volume Reduction]
        B --> G[Intensity Adjustment]
        C --> H[Exercise Selection]
        D --> I[Movement Substitution]
        E --> J[RPE Caps]
    end

    subgraph Output["Modified Plan"]
        F --> K[Adjusted Workout]
        G --> K
        H --> K
        I --> K
        J --> K
    end
```

## Modification Matrix

```mermaid
quadrantChart
    title Readiness vs Workout Modification
    x-axis Low Energy --> High Energy
    y-axis High Soreness --> Low Soreness
    quadrant-1 Standard Workout
    quadrant-2 Reduce Volume
    quadrant-3 Light/Active Recovery
    quadrant-4 Reduce Intensity
    
    Standard: [0.75, 0.75]
    Volume Down: [0.25, 0.75]
    Recovery: [0.25, 0.25]
    Intensity Down: [0.75, 0.25]
```

## AI Prompt Construction

```mermaid
sequenceDiagram
    participant App as StrengthTracker
    participant Context as Context Builder
    participant LLM as LLM Service
    participant Provider as Claude/OpenAI

    App->>Context: Readiness Data
    App->>Context: User Profile
    App->>Context: Workout Template
    App->>Context: Recent History
    
    Context->>LLM: Build System Prompt
    Context->>LLM: Build User Prompt
    
    LLM->>Provider: Send Request
    Provider-->>LLM: JSON Response
    
    LLM-->>App: Parsed Modifications
```

## Modification Types

```mermaid
classDiagram
    class WorkoutModification {
        +String reason
        +ModificationType type
        +Double factor
    }
    
    class VolumeModification {
        +Int originalSets
        +Int modifiedSets
        +String rationale
    }
    
    class IntensityModification {
        +Double originalRPE
        +Double modifiedRPE
        +Double weightFactor
    }
    
    class ExerciseSubstitution {
        +Exercise original
        +Exercise replacement
        +String reason
    }
    
    WorkoutModification <|-- VolumeModification
    WorkoutModification <|-- IntensityModification
    WorkoutModification <|-- ExerciseSubstitution
```

## Example Adjustments

### High Soreness (4-5)
```mermaid
flowchart LR
    A[High Soreness] --> B[Reduce Sets by 30-50%]
    A --> C[Lower RPE Cap to 7]
    A --> D[Substitute High-Impact Exercises]
    A --> E[Add Extra Warm-up Sets]
```

### Low Energy (1-2)
```mermaid
flowchart LR
    A[Low Energy] --> B[Reduce Total Volume]
    A --> C[Focus on Compound Movements]
    A --> D[Shorter Rest Periods Option]
    A --> E[Suggest Caffeine/Pre-workout]
```

### Time Constraint
```mermaid
flowchart LR
    A[Limited Time] --> B{Time Available}
    B -->|< 30 min| C[Essential Compounds Only]
    B -->|30-45 min| D[Remove Accessories]
    B -->|45-60 min| E[Supersets/Circuits]
    B -->|> 60 min| F[Full Workout]
```

## Offline Fallback

```mermaid
flowchart TD
    A[AI Call Failed] --> B[OfflineProgressionEngine]
    
    B --> C{Analyze Readiness}
    C --> D[Apply Rule-Based Adjustments]
    
    D --> E[Soreness Rules]
    D --> F[Energy Rules]
    D --> G[Time Rules]
    
    E --> H[Modified Workout]
    F --> H
    G --> H
    
    subgraph Rules["Rule-Based Logic"]
        E --> E1[Soreness 4-5: -30% volume]
        E --> E2[Soreness 3: -15% volume]
        F --> F1[Energy 1-2: -20% intensity]
        G --> G1[Time < 45: Remove isolation]
    end
```

## User Notification

```mermaid
flowchart TD
    A[Modifications Applied] --> B[Show Banner]
    B --> C[List Changes Made]
    
    C --> D[Volume Adjustments]
    C --> E[Intensity Changes]
    C --> F[Exercise Swaps]
    C --> G[Coaching Tips]
    
    B --> H[Tap for Details]
    H --> I[Full Explanation Sheet]
```
