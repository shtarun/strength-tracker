# Progression Logic

This document explains the training science and programming rules behind Strength Tracker's intelligent progression system.

## Table of Contents

- [Philosophy](#philosophy)
- [Progression Models](#progression-models)
- [e1RM Calculation](#e1rm-calculation)
- [Readiness Adjustments](#readiness-adjustments)
- [Warmup Generation](#warmup-generation)
- [Stall Detection](#stall-detection)
- [Exercise Substitution](#exercise-substitution)

---

## Philosophy

Strength Tracker follows evidence-based strength training principles:

1. **Progressive Overload** - Systematically increase training demands over time
2. **Auto-regulation** - Adjust training based on daily readiness and RPE
3. **Minimum Effective Dose** - Make the smallest change necessary to drive progress
4. **Fatigue Management** - Balance stress and recovery for long-term gains

---

## Progression Models

### Top Set + Backoffs (Primary)

Best for: **Compound lifts** (Squat, Bench, Deadlift, Row, OHP)

```
Warmups → Top Set → Backoff Sets
```

**Structure:**

| Component | Reps | RPE | Sets |
|-----------|------|-----|------|
| Warmups | 10, 5, 5, 3 | 5-6 | 3-4 |
| Top Set | 4-6 | 7.5-8.5 | 1 |
| Backoffs | 6-10 | Same RPE | 2-4 |

**Progression Rules:**

```
IF top set hit max reps AND RPE ≤ cap:
    Next session: +2.5kg (barbell) or +2kg (dumbbell)
    Reset to min reps
    
ELSE IF reps in range AND RPE < cap:
    Next session: Same weight, +1 rep
    
ELSE (struggling):
    Keep weight, focus on form
    If persistent, consider deload
```

**Example:**

| Week | Target | Actual | Next Session |
|------|--------|--------|--------------|
| 1 | 100kg × 4-6 @ RPE 8 | 100 × 4 @ 7.5 | 100 × 5 |
| 2 | 100kg × 5 | 100 × 5 @ 8 | 100 × 6 |
| 3 | 100kg × 6 | 100 × 6 @ 8 | **102.5 × 4** |
| 4 | 102.5kg × 4-6 | 102.5 × 4 @ 8.5 | 102.5 × 5 |

**Backoff Calculation:**

```swift
backoffWeight = topSetWeight * (1 - backoffLoadDropPercent)
// Example: 100kg top set with 10% drop = 90kg backoffs
```

### Double Progression

Best for: **Isolation exercises** and **hypertrophy focus**

```
Working Sets × Rep Range → Hit top of range → Increase weight
```

**Structure:**

| Component | Reps | RPE | Sets |
|-----------|------|-----|------|
| Working Sets | 8-12 | 8-9 | 3 |

**Progression Rules:**

```
IF all sets hit max reps AND RPE ≤ cap:
    Next session: +2kg (dumbbell) or +2.5kg (cable)
    Reset to min reps
    
ELSE:
    Same weight, try to add reps to lagging sets
```

**Example:**

| Week | Target | Set 1 | Set 2 | Set 3 | Next |
|------|--------|-------|-------|-------|------|
| 1 | 20kg × 8-12 | 12 | 11 | 10 | Same weight |
| 2 | 20kg × 8-12 | 12 | 12 | 11 | Same weight |
| 3 | 20kg × 8-12 | 12 | 12 | 12 | **+2kg** |
| 4 | 22kg × 8-12 | 10 | 9 | 8 | Same weight |

### Straight Sets

Best for: **Accessory work** and **beginners**

```
Fixed weight × Fixed reps × Fixed sets
```

Simple week-to-week progression when all sets completed successfully.

---

## e1RM Calculation

Estimated 1-Rep Max using the **Epley Formula**:

```swift
func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
    if reps == 1 { return weight }
    return weight * (1 + Double(reps) / 30.0)
}
```

**Formula:** `e1RM = weight × (1 + reps/30)`

**Accuracy:**
- Most accurate at 1-10 reps
- Increasingly overestimates above 10 reps
- Not used for 20+ rep sets

**Example Values:**

| Weight | Reps | e1RM |
|--------|------|------|
| 100kg | 1 | 100.0kg |
| 100kg | 5 | 116.7kg |
| 100kg | 10 | 133.3kg |
| 90kg | 8 | 114.0kg |

**Usage in App:**
- Track strength progress over time
- Compare sessions with different rep ranges
- Detect stalls (no e1RM improvement)

---

## Readiness Adjustments

Pre-workout readiness check modifies training:

### Input Categories

**Energy Level:**
| Level | Meaning |
|-------|---------|
| Low | Poor sleep, stressed, run down |
| OK | Normal day |
| High | Well rested, motivated |

**Soreness Level:**
| Level | Meaning |
|-------|---------|
| None | Fully recovered |
| Mild | Some DOMS, not limiting |
| High | Significant soreness, affects performance |

**Time Available:**
| Duration | Effect |
|----------|--------|
| 30 min | Skip all optional exercises |
| 45 min | Skip most optional exercises |
| 60 min | Normal session |
| 75+ min | Full session + extras |

### Adjustment Rules

```swift
var shouldReduceIntensity: Bool {
    energy == .low || soreness == .high
}

var shouldIncreaseIntensity: Bool {
    energy == .high && soreness == .none
}
```

**When Reducing Intensity:**

| Adjustment | Normal | Reduced |
|------------|--------|---------|
| RPE Cap | 8.0 | 7.5 |
| Backoff Sets | 3 | 2 |
| Optional Exercises | Include | Skip |

**When Increasing Intensity:**

| Adjustment | Normal | Increased |
|------------|--------|-----------|
| RPE Cap | 8.0 | 8.5 |
| Backoff Sets | 3 | 4 |
| Weight | As planned | Consider small bump |

### Implementation

```swift
func adjustedRPE(base: Double, readiness: Readiness) -> Double {
    switch (readiness.energy, readiness.soreness) {
    case (.low, _), (_, .high):
        return min(base, 7.5)  // Cap at 7.5
    case (.high, .none):
        return base + 0.5      // Allow harder effort
    default:
        return base            // No change
    }
}

func adjustedBackoffSets(base: Int, readiness: Readiness) -> Int {
    switch (readiness.energy, readiness.soreness) {
    case (.low, _), (_, .high):
        return max(1, base - 1)  // Reduce by 1
    case (.high, .none):
        return base + 1          // Add 1
    default:
        return base              // No change
    }
}
```

---

## Warmup Generation

Systematic warmups prepare joints, muscles, and nervous system.

### Algorithm

```swift
func generateWarmups(topSetWeight: Double) -> [PlannedSetResponse] {
    guard topSetWeight > 20 else { return [] }
    
    var warmups: [PlannedSetResponse] = []
    let barWeight = 20.0
    
    // Empty bar (if working weight allows)
    if topSetWeight > barWeight * 1.5 {
        warmups.append(PlannedSetResponse(
            weight: barWeight, 
            reps: 10, 
            rpeCap: 5, 
            setCount: 1
        ))
    }
    
    // Progressive warmups at 40%, 60%, 80%
    let percentages = [0.4, 0.6, 0.8]
    for percentage in percentages {
        let weight = topSetWeight * percentage
        if weight > barWeight {
            let reps = percentage < 0.7 ? 5 : 3
            warmups.append(PlannedSetResponse(
                weight: roundToNearest(weight, increment: 2.5),
                reps: reps,
                rpeCap: 6,
                setCount: 1
            ))
        }
    }
    
    return warmups
}
```

### Example Warmups

**Top Set: 140kg Squat**

| Set | Weight | % of Top | Reps | RPE |
|-----|--------|----------|------|-----|
| 1 | 20kg | 14% | 10 | 5 |
| 2 | 55kg | 40% | 5 | 5-6 |
| 3 | 85kg | 60% | 5 | 5-6 |
| 4 | 112.5kg | 80% | 3 | 6 |
| **Top** | **140kg** | 100% | 4-6 | 8 |

**Top Set: 50kg Bench (lighter loads)**

| Set | Weight | % of Top | Reps | RPE |
|-----|--------|----------|------|-----|
| 1 | 20kg | 40% | 5 | 5-6 |
| 2 | 30kg | 60% | 5 | 5-6 |
| 3 | 40kg | 80% | 3 | 6 |
| **Top** | **50kg** | 100% | 4-6 | 8 |

---

## Stall Detection

Identifies when progress has stopped.

### Criteria

```swift
func detectStall(exerciseId: UUID, history: [SetHistory]) -> StallAnalysis? {
    // Need at least 3 exposures
    guard history.count >= 3 else { return nil }
    
    let recent = history.prefix(3)
    let e1RMs = recent.map { estimatedOneRepMax(weight: $0.weight, reps: $0.reps) }
    
    let maxE1RM = e1RMs.max()!
    let oldestE1RM = e1RMs.last!
    
    // Stall: no improvement in e1RM
    if maxE1RM <= oldestE1RM {
        return StallAnalysis(
            exerciseId: exerciseId,
            stallDuration: 3,
            suggestedFix: determineFix(history: Array(recent)),
            reasoning: "No e1RM improvement in 3 sessions"
        )
    }
    
    return nil
}
```

### Stall Indicators

| Indicator | Definition |
|-----------|------------|
| No e1RM improvement | Max e1RM in last 3 sessions ≤ oldest e1RM |
| Missed reps | Consistently below target reps |
| RPE creep | RPE rising while performance flat |
| Form breakdown | (User-flagged) Technique deteriorating |

### Fix Suggestions

```swift
func determineFix(history: [SetHistory]) -> StallFix {
    let avgRPE = history.compactMap(\.rpe).average() ?? 8.0
    let avgReps = history.map(\.reps).average()
    
    // High RPE → Fatigue accumulation → Deload
    if avgRPE >= 9.0 {
        return .deload(percentage: 0.08)  // 8% reduction
    }
    
    // Low reps stuck → Need volume → Rep range change
    if avgReps <= 4 {
        return .repRangeChange(from: "3-5", to: "6-8")
    }
    
    // Otherwise → Neural staleness → Variation swap
    return .variationSwap
}
```

**Fix Types:**

| Fix | When to Use | Implementation |
|-----|-------------|----------------|
| Micro-deload | RPE consistently high (9+) | Reduce weight 7-10% for 1 week |
| Rep range change | Stuck at low reps | Switch 4-6 → 6-8 for 2-3 weeks |
| Variation swap | Long-term plateau | Similar exercise (e.g., Bench → Incline) |
| Volume tweak | Volume-related stall | Add/remove 1-2 sets per week |

---

## Exercise Substitution

Maps exercises to alternatives based on equipment and pain.

### Substitution Graph

```swift
let substitutionGraph: [String: [String]] = [
    // Horizontal Push
    "Bench Press": [
        "Dumbbell Bench Press", 
        "Floor Press", 
        "Weighted Push-ups", 
        "Machine Chest Press"
    ],
    
    // Horizontal Pull
    "Barbell Row": [
        "Dumbbell Row", 
        "Chest Supported Row", 
        "Cable Row", 
        "Inverted Rows"
    ],
    
    // Squat Pattern
    "Barbell Squat": [
        "Goblet Squat", 
        "Bulgarian Split Squat", 
        "Leg Press", 
        "Hack Squat"
    ],
    
    // Hinge Pattern
    "Deadlift": [
        "Romanian Deadlift", 
        "Trap Bar Deadlift", 
        "Dumbbell RDL"
    ],
    
    // Vertical Push
    "Overhead Press": [
        "Dumbbell Shoulder Press", 
        "Landmine Press", 
        "Pike Push-ups"
    ],
    
    // Vertical Pull
    "Pull-ups": [
        "Lat Pulldown", 
        "Banded Pull-ups", 
        "Inverted Rows"
    ]
]
```

### Substitution Logic

```swift
func findSubstitute(
    for exercise: String,
    availableEquipment: Set<Equipment>,
    painFlags: [PainFlag]
) -> String? {
    guard let alternatives = substitutionGraph[exercise] else {
        return nil
    }
    
    for alternative in alternatives {
        // Check equipment availability
        let altExercise = exerciseLibrary.find(named: alternative)
        let requiredEquipment = Set(altExercise.equipmentRequired)
        
        if !requiredEquipment.isSubset(of: availableEquipment) {
            continue  // Can't do this one
        }
        
        // Check pain flags
        let affectedMuscles = painFlags.flatMap { $0.affectedMuscles }
        let exerciseMuscles = Set(altExercise.allMuscles)
        
        if !exerciseMuscles.isDisjoint(with: affectedMuscles) {
            continue  // Might aggravate pain
        }
        
        return alternative  // Found a valid substitute
    }
    
    return nil  // No valid substitute found
}
```

### Substitution Reasons

| Reason | Example |
|--------|---------|
| Equipment missing | No barbell → Dumbbell variation |
| Pain flag | Shoulder pain → Neutral grip or machine |
| Time constraint | Skip isolation work |
| User preference | (Future) "I don't like this exercise" |

---

## Weight Increments

Standard progression steps based on equipment and load.

### Increment Rules

```swift
func nextWeight(from current: Double, exercise: Exercise) -> Double {
    if exercise.isCompound && exercise.equipmentRequired.contains(.barbell) {
        // Barbell compounds: standard plates
        return current + 2.5  // kg
    } else if exercise.equipmentRequired.contains(.dumbbell) {
        // Dumbbells: typically 2kg jumps
        return current + 2.0  // kg per dumbbell
    } else {
        // Cables, machines: smaller increments
        return current + 1.25  // or next available
    }
}
```

### Dumbbell Availability

Not all gyms have every dumbbell weight. The app considers:

```swift
let standardDumbbells = [
    2, 4, 6, 8, 10, 12.5, 15, 17.5, 20, 
    22.5, 25, 27.5, 30, 32.5, 35, 37.5, 40,
    42.5, 45, 47.5, 50
]  // kg

func nextAvailableDumbbell(from current: Double) -> Double {
    let available = profile.dumbbellIncrements.isEmpty 
        ? standardDumbbells 
        : profile.dumbbellIncrements
    
    return available.first { $0 > current } ?? current
}
```

### Plate Math

For barbell exercises, weight must be achievable:

```swift
func isAchievable(weight: Double, plates: [Double]) -> Bool {
    let barWeight = 20.0
    let loadPerSide = (weight - barWeight) / 2
    
    // Check if loadPerSide can be made with available plates
    return canMakeWeight(loadPerSide, from: plates)
}
```

---

## See Also

- [Agent System](AGENT_SYSTEM.md) - AI implementation
- [Data Models](DATA_MODELS.md) - Entity structures
- [API Reference](API_REFERENCE.md) - Full type documentation
