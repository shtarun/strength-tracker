# Plan Progression Flow

This document describes how workout plans progress through weeks and track completion.

## Overview

StrengthTracker automatically manages plan progression, advancing users through weeks as they complete workouts, and handling deload/peak weeks appropriately.

## Main Flow Diagram

```mermaid
flowchart TD
    subgraph Activation["📅 Plan Activation"]
        A[User Creates Plan] --> B[Plan Saved<br/>isActive: false]
        B --> C[User Taps 'Start Plan']
        C --> D[Deactivate Other Plans]
        D --> E[Set isActive: true]
        E --> F[Set startDate: now]
        F --> G[currentWeek: 1]
    end

    subgraph Workout["💪 Workout Completion"]
        G --> H[User Completes Workout]
        H --> I[Increment completedWorkoutsThisWeek]
        I --> J{Enough Workouts?}
        J -->|No| K[Wait for Next Workout]
        K --> H
        J -->|Yes| L[Trigger Week Advancement]
    end

    subgraph Advance["⏭️ Week Advancement"]
        L --> M[Mark Current Week Complete]
        M --> N{More Weeks?}
        N -->|Yes| O[currentWeek += 1]
        O --> P[Reset completedWorkoutsThisWeek]
        P --> Q[Load Next Week Templates]
        N -->|No| R[Plan Complete!]
        R --> S[isActive: false]
    end

    style C fill:#4CAF50,color:white
    style L fill:#2196F3,color:white
    style R fill:#FF9800,color:white
```

## Week Type Handling

```mermaid
flowchart TD
    A[Load Week] --> B{Week Type?}
    
    B -->|Regular| C[Standard Training]
    B -->|Deload| D[Apply Deload Modifiers]
    B -->|Peak| E[Apply Peak Modifiers]
    B -->|Test| F[Max Testing Protocol]
    
    subgraph Regular["Regular Week"]
        C --> C1[100% Intensity]
        C --> C2[100% Volume]
        C --> C3[RPE Cap: 10]
    end
    
    subgraph Deload["Deload Week"]
        D --> D1[60% Intensity]
        D --> D2[50% Volume]
        D --> D3[RPE Cap: 7]
        D --> D4[Show Recovery Tips]
    end
    
    subgraph Peak["Peak Week"]
        E --> E1[105% Intensity]
        E --> E2[70% Volume]
        E --> E3[RPE Cap: 9.5]
        E --> E4[Show Peak Advice]
    end
    
    subgraph Test["Test Week"]
        F --> F1[100% Intensity]
        F --> F2[30% Volume]
        F --> F3[RPE Cap: 10]
        F --> F4[PR Tracking Mode]
    end
```

## State Machine

```mermaid
stateDiagram-v2
    [*] --> NotStarted: Plan Created
    
    NotStarted --> Week1: Activate Plan
    
    Week1 --> Week2: Complete Week
    Week2 --> Week3: Complete Week
    Week3 --> Week4: Complete Week
    Week4 --> WeekN: ...
    WeekN --> Completed: Final Week Done
    
    Week1 --> Paused: Pause Plan
    Week2 --> Paused: Pause Plan
    Week3 --> Paused: Pause Plan
    Week4 --> Paused: Pause Plan
    WeekN --> Paused: Pause Plan
    
    Paused --> Week1: Resume
    Paused --> Week2: Resume
    Paused --> Week3: Resume
    Paused --> Week4: Resume
    
    Completed --> [*]
    
    note right of Paused
        User can pause at any point
        Progress is preserved
    end note
```

## Progress Calculation

```mermaid
flowchart LR
    subgraph Inputs["Progress Inputs"]
        A[completedWeeks]
        B[durationWeeks]
        C[completedWorkoutsThisWeek]
        D[workoutsPerWeek]
    end

    subgraph Formula["Calculation"]
        A --> E[weekProgress = completed / duration]
        C --> F[currentWeekProgress = workouts / perWeek / duration]
        E --> G[total = weekProgress + currentWeekProgress]
        F --> G
    end

    subgraph Output["Display"]
        G --> H[Progress Bar]
        G --> I[Percentage Text]
        G --> J[Weeks Remaining]
    end
```

## Weekly Transition

```mermaid
sequenceDiagram
    participant User
    participant Session as WorkoutSession
    participant Plan as WorkoutPlan
    participant Week as PlanWeek
    participant Service as PlanProgressService

    User->>Session: Complete Workout
    Session->>Plan: recordCompletedWorkout()
    Plan->>Plan: completedWorkoutsThisWeek++
    
    Plan->>Plan: advanceWeekIfNeeded()
    
    alt Workouts Complete
        Plan->>Week: isCompleted = true
        Plan->>Plan: currentWeek++
        Plan->>Plan: completedWorkoutsThisWeek = 0
        Plan-->>User: Show "Week Complete" 🎉
    else Workouts Remaining
        Plan-->>User: Show Progress Update
    end
    
    Note over Plan: Check if final week
    
    alt Plan Complete
        Plan->>Plan: isActive = false
        Plan-->>User: Show "Plan Complete" 🏆
    end
```

## Plan Lifecycle

```mermaid
gantt
    title 8-Week Plan Timeline
    dateFormat  YYYY-MM-DD
    section Planning
    Create Plan           :done, p1, 2024-01-01, 1d
    Review & Adjust       :done, p2, after p1, 1d
    
    section Execution
    Week 1 - Regular      :active, w1, 2024-01-03, 7d
    Week 2 - Regular      :w2, after w1, 7d
    Week 3 - Regular      :w3, after w2, 7d
    Week 4 - Deload       :crit, w4, after w3, 7d
    Week 5 - Regular      :w5, after w4, 7d
    Week 6 - Regular      :w6, after w5, 7d
    Week 7 - Peak         :w7, after w6, 7d
    Week 8 - Test         :milestone, w8, after w7, 7d
    
    section Completion
    Review Results        :r1, after w8, 2d
```

## UI State Updates

```mermaid
flowchart TD
    subgraph HomeScreen["Home Screen"]
        H1[Active Plan Card]
        H2[Current Week Display]
        H3[Progress Ring]
        H4[Next Workout Button]
    end

    subgraph PlanDetail["Plan Detail View"]
        P1[Week List]
        P2[Current Week Highlight]
        P3[Completed Checkmarks]
        P4[Progress Stats]
    end

    subgraph Updates["State Changes"]
        U1[Workout Completed]
        U2[Week Advanced]
        U3[Plan Completed]
    end

    U1 --> H3
    U1 --> P4
    
    U2 --> H2
    U2 --> P1
    U2 --> P2
    
    U3 --> H1
    U3 --> P3
```

## Edge Cases

```mermaid
flowchart TD
    subgraph Scenarios["Edge Case Handling"]
        A[Skip Workout] --> A1[Manual Week Skip Option]
        B[Extra Workout] --> B1[Counts Toward Next Week]
        C[Missed Week] --> C1[Option to Extend Plan]
        D[Plan Reset] --> D1[Clear Progress, Keep Structure]
    end

    subgraph Actions["Available Actions"]
        A1 --> E[skipToWeek method]
        B1 --> F[Overflow handling]
        C1 --> G[Plan extension UI]
        D1 --> H[resetPlan method]
    end
```

## Analytics Events

```mermaid
flowchart LR
    subgraph Events["Tracked Events"]
        E1[plan_activated]
        E2[workout_completed]
        E3[week_advanced]
        E4[plan_completed]
        E5[plan_paused]
        E6[plan_resumed]
    end

    subgraph Data["Event Data"]
        E1 --> D1[plan_id, duration, goal]
        E2 --> D2[plan_id, week, workout_num]
        E3 --> D3[plan_id, from_week, to_week]
        E4 --> D4[plan_id, total_days, completion_rate]
    end
```
