# Workout Execution Flow

This document describes the complete flow of executing a workout from start to finish.

## Overview

A workout session involves selecting/starting a workout, completing exercises with sets, and finishing with a summary. AI assists with readiness adjustments and progression recommendations.

## Complete Flow Diagram

```mermaid
flowchart TD
    subgraph Selection["🏠 Workout Selection"]
        A[Open App] --> B{Active Plan?}
        B -->|Yes| C[Show Plan's Current Week]
        B -->|No| D[Show All Templates]
        
        C --> E[Select Workout]
        D --> E
        E --> F[Tap 'Start Workout']
    end

    subgraph Readiness["📋 Readiness Check"]
        F --> G{Check Recent Readiness}
        G -->|Fresh| H[Use Existing]
        G -->|Stale/None| I[Show Readiness Sheet]
        
        I --> J[Complete Check]
        J --> K{Non-Default Values?}
        K -->|Yes| L[🤖 AI Customization]
        K -->|No| M[Use Standard Plan]
        
        H --> M
        L --> M
    end

    subgraph Session["💪 Workout Session"]
        M --> N[Create WorkoutSession]
        N --> O[Show First Exercise]
        
        O --> P[Log Set]
        P --> Q{More Sets?}
        Q -->|Yes| R[Rest Timer]
        R --> P
        Q -->|No| S{More Exercises?}
        S -->|Yes| T[Next Exercise]
        T --> P
        S -->|No| U[Finish Workout]
    end

    subgraph Completion["✅ Completion"]
        U --> V[Calculate Stats]
        V --> W[Show Summary]
        W --> X[🤖 AI Feedback]
        X --> Y{Plan Active?}
        Y -->|Yes| Z[Update Plan Progress]
        Y -->|No| AA[Save Session]
        Z --> AA
        AA --> AB[Return Home]
    end

    style L fill:#4CAF50,color:white
    style X fill:#4CAF50,color:white
    style Z fill:#2196F3,color:white
```

## Exercise Logging Detail

```mermaid
flowchart TD
    subgraph Exercise["Current Exercise"]
        A[Exercise View]
        A1[Name & Instructions]
        A2[Target: 4x8 @ RPE 8]
        A3[Previous: 135 lbs x 8]
    end

    subgraph Logging["Set Logging"]
        B[Weight Input]
        C[Reps Input]
        D[RPE Selector]
        E[Notes - Optional]
        F[Log Set Button]
    end

    subgraph SetTypes["Set Types"]
        G[Working Set]
        H[Warm-up Set]
        I[Top Set]
        J[Backoff Set]
        K[Drop Set]
    end

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    
    F --> L{Set Type}
    L --> G
    L --> H
    L --> I
    L --> J
    L --> K
```

## Rest Timer Flow

```mermaid
flowchart TD
    A[Set Logged] --> B[Show Rest Timer]
    B --> C{Timer Running}
    
    C --> D[Display Countdown]
    D --> E{Time Up?}
    
    E -->|No| F[Continue Counting]
    F --> C
    
    E -->|Yes| G[Vibrate/Sound Alert]
    G --> H[Show 'Ready' Button]
    
    B --> I[Skip Timer Option]
    I --> H
    
    H --> J[Log Next Set]
    
    subgraph Timer["Timer Details"]
        T1[Based on Exercise Type]
        T2[Compound: 2-3 min]
        T3[Isolation: 60-90 sec]
        T4[User Adjustable]
    end
```

## Progression System

```mermaid
flowchart TD
    subgraph Analysis["Set Analysis"]
        A[Log Final Set]
        A --> B[Compare to Target]
        B --> C{Met Target?}
    end

    subgraph Success["Target Met"]
        C -->|Yes| D{Exceeded?}
        D -->|Yes| E[🤖 Suggest Weight Increase]
        D -->|No| F[Maintain Weight]
    end

    subgraph Failure["Target Missed"]
        C -->|No| G{How Much?}
        G -->|Slight Miss| H[Retry Next Session]
        G -->|Significant| I[🤖 Analyze Cause]
        I --> J[Suggest Deload?]
    end

    subgraph Progression["Progression Rules"]
        E --> K[+5 lbs Lower Body]
        E --> L[+2.5 lbs Upper Body]
        E --> M[+1 Rep Next Time]
    end
```

## Pause & Resume Flow

```mermaid
flowchart TD
    A[Workout In Progress] --> B{User Action}
    
    B -->|Pause| C[Tap Pause Button]
    C --> D[Save Current State]
    D --> E[Create PausedWorkout]
    E --> F[Store to SwiftData]
    F --> G[Return to Home]
    
    B -->|App Backgrounded| H[Auto-Save State]
    H --> E
    
    subgraph Resume["Resume Flow"]
        I[Open App] --> J{Paused Workout?}
        J -->|Yes| K[Show Resume Banner]
        K --> L[Tap Resume]
        L --> M[Load PausedWorkout]
        M --> N[Restore Session State]
        N --> O[Continue from Last Set]
    end
    
    G --> I
```

## Workout Summary

```mermaid
flowchart TD
    subgraph Stats["Session Statistics"]
        A[Total Duration]
        B[Sets Completed]
        C[Total Volume]
        D[Exercises Done]
        E[PRs Hit]
    end

    subgraph Analysis["🤖 AI Analysis"]
        F[Performance vs Target]
        G[Recovery Recommendations]
        H[Next Session Preview]
        I[Coaching Notes]
    end

    subgraph Actions["Post-Workout"]
        J[Save to History]
        K[Update PRs]
        L[Update Plan Progress]
        M[Share Option]
    end

    Stats --> Analysis
    Analysis --> Actions
```

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant View as WorkoutView
    participant Session as WorkoutSession
    participant Set as WorkoutSet
    participant Plan as WorkoutPlan
    participant DB as SwiftData

    User->>View: Start Workout
    View->>Session: Create Session
    Session->>DB: Save Session
    
    loop Each Exercise
        loop Each Set
            User->>View: Log Set
            View->>Set: Create WorkoutSet
            Set->>Session: Add to Session
            Session->>DB: Save Set
        end
    end
    
    User->>View: Finish Workout
    View->>Session: Complete Session
    Session->>Session: Calculate Stats
    
    alt Has Active Plan
        Session->>Plan: recordCompletedWorkout()
        Plan->>DB: Update Progress
    end
    
    Session->>DB: Final Save
    View->>User: Show Summary
```

## Exercise Navigation

```mermaid
flowchart LR
    subgraph Navigation["Exercise Navigation"]
        A[Previous] --> B[Current Exercise]
        B --> C[Next]
        
        D[Exercise List] --> E[Jump to Any]
        E --> B
    end

    subgraph Status["Exercise Status"]
        F[⚪ Not Started]
        G[🟡 In Progress]
        H[🟢 Completed]
        I[⏭️ Skipped]
    end
```

## Error Handling

```mermaid
flowchart TD
    A[Workout Session] --> B{Error Type}
    
    B -->|App Crash| C[Auto-Recovery]
    C --> D[Load Last Saved State]
    
    B -->|Data Loss| E[Backup Restore]
    E --> F[Prompt User]
    
    B -->|Invalid Input| G[Validation Error]
    G --> H[Show Error Message]
    H --> I[Retry Input]
    
    B -->|Network Error| J[Offline Mode]
    J --> K[Queue AI Requests]
    K --> L[Sync When Online]
```

## Offline Capability

```mermaid
flowchart TD
    subgraph Online["Online Mode"]
        A[Full AI Features]
        B[Real-time Sync]
        C[Cloud Backup]
    end

    subgraph Offline["Offline Mode"]
        D[Local Progression Engine]
        E[Local Storage]
        F[Queued Requests]
    end

    subgraph Sync["Sync Process"]
        G[Connection Restored]
        G --> H[Process Queue]
        H --> I[Merge Data]
        I --> J[Resolve Conflicts]
    end

    Online --> |Connection Lost| Offline
    Offline --> |Reconnected| Sync
    Sync --> Online
```

## Performance Tracking

```mermaid
flowchart TD
    subgraph Metrics["Tracked Metrics"]
        A[Weight Used]
        B[Reps Completed]
        C[RPE Logged]
        D[Rest Times]
        E[Session Duration]
    end

    subgraph Calculations["Derived Stats"]
        A --> F[E1RM Calculation]
        A --> G[Volume Load]
        B --> G
        C --> H[Fatigue Index]
        D --> I[Work Capacity]
    end

    subgraph Trends["Progress Trends"]
        F --> J[Strength Curve]
        G --> K[Volume Trends]
        H --> L[Recovery Needs]
    end
```
