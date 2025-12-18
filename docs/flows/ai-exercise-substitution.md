# AI Exercise Substitution Flow

This document describes how the AI suggests alternative exercises when users need to swap an exercise.

## Overview

Users may need to substitute exercises due to equipment unavailability, injury, preference, or variety. The AI provides intelligent alternatives that maintain training effectiveness.

## Flow Diagram

```mermaid
flowchart TD
    subgraph Trigger["🎯 Substitution Triggers"]
        A1[Equipment Unavailable]
        A2[Pain/Discomfort]
        A3[User Preference]
        A4[Seeking Variety]
    end

    subgraph Request["📱 User Action"]
        A1 --> B[Long Press Exercise]
        A2 --> B
        A3 --> B
        A4 --> B
        B --> C[Tap 'Find Alternative']
    end

    subgraph Analysis["🔍 Exercise Analysis"]
        C --> D[Identify Movement Pattern]
        D --> E[List Primary Muscles]
        E --> F[Check Equipment Available]
        F --> G[Review User History]
    end

    subgraph AIGen["🤖 AI Generation"]
        G --> H{AI Enabled?}
        H -->|Yes| I[Build Context]
        H -->|No| J[Use Substitution Graph]
        
        I --> K[Query LLM]
        K --> L[Parse Suggestions]
        L --> M[Rank Alternatives]
        
        J --> M
    end

    subgraph Display["📋 Results"]
        M --> N[Show Top 5 Alternatives]
        N --> O[Each with Similarity Score]
        O --> P[Equipment Indicators]
        P --> Q[Tap to Substitute]
    end

    style H fill:#2196F3,color:white
    style K fill:#4CAF50,color:white
    style N fill:#FF9800,color:white
```

## Substitution Logic

```mermaid
flowchart TD
    subgraph Exercise["Original Exercise"]
        A[Barbell Bench Press]
        A1[Pattern: Horizontal Push]
        A2[Primary: Chest]
        A3[Secondary: Triceps, Front Delt]
        A4[Equipment: Barbell, Bench]
    end

    subgraph Matching["Matching Criteria"]
        B1[Same Movement Pattern]
        B2[Same Primary Muscles]
        B3[Available Equipment]
        B4[Similar Difficulty]
    end

    subgraph Results["Alternatives"]
        C1[Dumbbell Bench Press<br/>95% match]
        C2[Machine Chest Press<br/>85% match]
        C3[Push-ups<br/>75% match]
        C4[Cable Flyes<br/>65% match]
    end

    A --> B1
    A1 --> B1
    A2 --> B2
    A3 --> B2
    A4 --> B3
    
    B1 --> C1
    B2 --> C1
    B3 --> C2
    B1 --> C3
```

## Substitution Graph

```mermaid
graph TD
    subgraph Horizontal_Push["Horizontal Push"]
        HP1[Barbell Bench]
        HP2[Dumbbell Bench]
        HP3[Machine Press]
        HP4[Push-ups]
        HP5[Cable Flyes]
        
        HP1 <--> HP2
        HP2 <--> HP3
        HP3 <--> HP4
        HP1 <--> HP4
        HP2 <--> HP5
    end

    subgraph Vertical_Push["Vertical Push"]
        VP1[OHP]
        VP2[Dumbbell Press]
        VP3[Machine Press]
        VP4[Landmine Press]
        
        VP1 <--> VP2
        VP2 <--> VP3
        VP3 <--> VP4
    end

    subgraph Horizontal_Pull["Horizontal Pull"]
        HR1[Barbell Row]
        HR2[Dumbbell Row]
        HR3[Cable Row]
        HR4[Machine Row]
        
        HR1 <--> HR2
        HR2 <--> HR3
        HR3 <--> HR4
    end
```

## AI Context Building

```mermaid
sequenceDiagram
    participant User
    participant View as Exercise View
    participant Service as LLMService
    participant Graph as SubstitutionGraph
    participant LLM as Claude/OpenAI

    User->>View: Request Substitution
    View->>Service: getSubstitutes(exercise)
    
    Service->>Graph: Get Base Alternatives
    Graph-->>Service: Candidate List
    
    Service->>Service: Build Prompt
    Note over Service: Include:<br/>- Movement pattern<br/>- Target muscles<br/>- Available equipment<br/>- User injuries<br/>- Recent exercises
    
    Service->>LLM: Query with Context
    LLM-->>Service: Ranked Suggestions
    
    Service->>Service: Merge & Rank
    Service-->>View: Final Alternatives
    View-->>User: Display Options
```

## Request Structure

```mermaid
classDiagram
    class SubstitutionRequest {
        +Exercise original
        +Equipment[] available
        +Muscle[]? avoidMuscles
        +String? injuryNotes
        +Int maxSuggestions
    }
    
    class SubstitutionResponse {
        +Alternative[] alternatives
        +String reasoning
    }
    
    class Alternative {
        +Exercise exercise
        +Double similarityScore
        +String[] matchingFactors
        +String[] differences
        +String coachingNote
    }
    
    SubstitutionRequest --> SubstitutionResponse
    SubstitutionResponse --> Alternative
```

## Similarity Scoring

```mermaid
flowchart LR
    subgraph Factors["Scoring Factors"]
        A[Movement Pattern<br/>Weight: 40%]
        B[Primary Muscles<br/>Weight: 30%]
        C[Equipment Type<br/>Weight: 15%]
        D[Difficulty Level<br/>Weight: 10%]
        E[User History<br/>Weight: 5%]
    end

    subgraph Calculation["Score Calculation"]
        A --> F[Pattern Match: 0-100]
        B --> G[Muscle Overlap: 0-100]
        C --> H[Equipment Similarity: 0-100]
        D --> I[Difficulty Delta: 0-100]
        E --> J[Familiarity Bonus: 0-100]
    end

    subgraph Result["Final Score"]
        F --> K[Weighted Sum]
        G --> K
        H --> K
        I --> K
        J --> K
        K --> L[0-100% Match]
    end
```

## Injury-Aware Substitution

```mermaid
flowchart TD
    A[User Reports Pain] --> B{Pain Location}
    
    B -->|Shoulder| C[Avoid Overhead Movements]
    B -->|Lower Back| D[Avoid Spinal Loading]
    B -->|Knee| E[Avoid Deep Flexion]
    B -->|Wrist| F[Avoid Gripping Stress]
    
    C --> G[Filter Alternatives]
    D --> G
    E --> G
    F --> G
    
    G --> H[Safe Alternatives Only]
    
    subgraph Examples["Example Substitutions"]
        C --> C1[OHP → Landmine Press]
        D --> D1[Deadlift → Hip Thrust]
        E --> E1[Squat → Leg Press (limited ROM)]
        F --> F1[Barbell Curl → Cable Curl]
    end
```

## User Selection Flow

```mermaid
flowchart TD
    A[View Alternatives] --> B[Tap Alternative]
    B --> C{Confirm Swap?}
    
    C -->|Yes| D[Update Workout]
    C -->|No| E[Return to List]
    
    D --> F[Log Substitution]
    F --> G[Update Template?]
    
    G -->|Yes| H[Save to Template]
    G -->|No| I[One-time Swap]
    
    H --> J[Continue Workout]
    I --> J
```

## Equipment-Based Filtering

```mermaid
flowchart TD
    subgraph Available["User's Equipment"]
        E1[✓ Barbell]
        E2[✓ Dumbbells]
        E3[✗ Cables]
        E4[✓ Bench]
        E5[✗ Machines]
    end

    subgraph Original["Original Exercise"]
        O[Cable Flyes<br/>Requires: Cables]
    end

    subgraph Filtered["Filtered Alternatives"]
        F1[Dumbbell Flyes ✓]
        F2[Push-ups ✓]
        F3[Dumbbell Bench ✓]
        F4[Machine Flyes ✗]
        F5[Pec Deck ✗]
    end

    Available --> Filtered
    Original --> Filtered
```
