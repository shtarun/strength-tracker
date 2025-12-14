# Views & UI

This document describes the SwiftUI view hierarchy, navigation structure, and key UI components in Strength Tracker.

## Table of Contents

- [Navigation Structure](#navigation-structure)
- [Screen Hierarchy](#screen-hierarchy)
- [Tab Views](#tab-views)
  - [Home Tab](#home-tab)
  - [Templates Tab](#templates-tab)
  - [Progress Tab](#progress-tab)
  - [Profile Tab](#profile-tab)
- [Modal Flows](#modal-flows)
- [Reusable Components](#reusable-components)
- [State Management](#state-management)

---

## Navigation Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    StrengthTrackerApp                        │
│                         │                                    │
│                    ContentView                               │
│                    ┌────┴────┐                              │
│                    ▼         ▼                              │
│            OnboardingFlow   MainTabView                     │
│            (first run)      (normal)                        │
│                              │                              │
│         ┌────────┬───────────┼───────────┬────────┐        │
│         ▼        ▼           ▼           ▼        ▼        │
│      HomeView  Templates  Progress   Profile  (Workout)   │
│         │                                       Full       │
│    ┌────┴────┐                                 Screen      │
│    ▼         ▼                                 Cover       │
│  Readiness  Workout                                        │
│   Sheet      View                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen Hierarchy

### Entry Point

**File:** `App/StrengthTrackerApp.swift`

```swift
@main
struct StrengthTrackerApp: App {
    let modelContainer: ModelContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    seedDataIfNeeded()  // Initialize exercises & fix empty templates
                }
        }
        .modelContainer(modelContainer)
    }
}
```

### Content Router

**File:** `App/ContentView.swift`

Routes between onboarding and main app:

```swift
struct ContentView: View {
    @Query private var userProfiles: [UserProfile]
    
    var body: some View {
        Group {
            if userProfiles.isEmpty {
                OnboardingFlow()    // First-time user
            } else {
                MainTabView()       // Returning user
            }
        }
    }
}
```

### Main Tab View

```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            TemplatesView()
                .tabItem { Label("Templates", systemImage: "list.bullet.rectangle") }
                .tag(1)
            
            ProgressView_Custom()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)
            
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
    }
}
```

---

## Tab Views

### Home Tab

**File:** `Views/Home/HomeView.swift`

Dashboard showing today's workout and quick stats.

```swift
struct HomeView: View {
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var recentSessions: [WorkoutSession]
    
    @State private var showReadinessCheck = false
    @State private var showActiveWorkout = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var todayPlan: TodayPlanResponse?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GreetingCard(name: profile.name)
                    
                    TodayWorkoutCard(
                        template: nextTemplate,
                        onStart: { /* Show readiness check */ }
                    )
                    
                    StatsCard(sessions: recentSessions)
                    
                    RecentWorkoutsSection(sessions: recentSessions.prefix(3))
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}
```

**Key Components:**

| Component | Purpose |
|-----------|---------|
| `GreetingCard` | Personalized welcome message |
| `TodayWorkoutCard` | Next workout with Start button |
| `StatsCard` | Weekly volume, session count |
| `RecentWorkoutsSection` | Last 3 workouts summary |

**State Flow:**

```
Start Workout tap
       │
       ▼
┌──────────────────┐
│ ReadinessCheck   │ ◄── Sheet presentation
│ (energy/soreness)│
└────────┬─────────┘
         │ onStart callback
         ▼
┌──────────────────┐
│ startWorkout()   │
│ - Create session │
│ - Generate plan  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   WorkoutView    │ ◄── Full screen cover
│  (active workout)│
└──────────────────┘
```

---

### Templates Tab

**File:** `Views/Templates/TemplatesView.swift`

Manage workout templates (programs).

```swift
struct TemplatesView: View {
    @Query(sort: \WorkoutTemplate.dayNumber) private var templates: [WorkoutTemplate]
    
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showEditor = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    TemplateRow(template: template)
                        .onTapGesture {
                            selectedTemplate = template
                            showEditor = true
                        }
                }
                .onDelete(perform: deleteTemplates)
                .onMove(perform: moveTemplates)
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { /* Add new template */ }
                    label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showEditor) {
                TemplateEditorView(template: selectedTemplate!)
            }
        }
    }
}
```

**Template Editor:**

```swift
struct TemplateEditorView: View {
    @Bindable var template: WorkoutTemplate
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $template.name)
                    Stepper("Duration: \(template.targetDuration) min", 
                            value: $template.targetDuration, in: 30...120, step: 15)
                }
                
                Section("Exercises") {
                    ForEach(template.sortedExercises) { exerciseTemplate in
                        ExerciseTemplateRow(exerciseTemplate: exerciseTemplate)
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)
                    
                    Button { showExercisePicker = true }
                    label: { Label("Add Exercise", systemImage: "plus") }
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Template")
                    }
                }
            }
        }
    }
}
```

---

### Progress Tab

**File:** `Views/Progress/ProgressView.swift`

Analytics and workout history.

```swift
struct ProgressView_Custom: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) 
    private var sessions: [WorkoutSession]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Recent Workouts") {
                    ForEach(sessions) { session in
                        SessionRow(session: session)
                    }
                }
                
                Section("Strength Progress") {
                    // e1RM charts per exercise
                }
                
                Section("Volume") {
                    // Weekly sets per muscle group
                }
            }
            .navigationTitle("Progress")
        }
    }
}
```

---

### Profile Tab

**File:** `Views/Profile/ProfileView.swift`

User settings and preferences.

```swift
struct ProfileView: View {
    @Query private var userProfiles: [UserProfile]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    TextField("Name", text: $profile.name)
                    Picker("Goal", selection: $profile.goal) { ... }
                }
                
                Section("Training") {
                    Picker("Split", selection: $profile.preferredSplit) { ... }
                    Stepper("Days per week: \(profile.daysPerWeek)", 
                            value: $profile.daysPerWeek, in: 2...6)
                }
                
                Section("Preferences") {
                    Picker("Units", selection: $profile.unitSystem) { ... }
                    Toggle("Show RPE", isOn: $profile.rpeFamiliarity)
                    // Rest time, etc.
                }
                
                Section("AI Coach") {
                    Picker("Provider", selection: $profile.preferredLLMProvider) { ... }
                    if profile.preferredLLMProvider == .claude {
                        SecureField("API Key", text: claudeKeyBinding)
                    }
                }
                
                Section("Equipment") {
                    NavigationLink("Equipment Profile") {
                        EquipmentProfileView(profile: profile.equipmentProfile!)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
```

---

## Modal Flows

### Onboarding Flow

**File:** `Views/Onboarding/OnboardingFlow.swift`

Multi-step onboarding for new users.

```swift
struct OnboardingFlow: View {
    @State private var currentStep = 0
    private let totalSteps = 6
    
    var body: some View {
        NavigationStack {
            VStack {
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                
                TabView(selection: $currentStep) {
                    WelcomeStep(name: $name)                    // Step 0
                        .tag(0)
                    GoalStep(goal: $goal, unitSystem: $unitSystem)  // Step 1
                        .tag(1)
                    SplitStep(daysPerWeek: $daysPerWeek, split: $split)  // Step 2
                        .tag(2)
                    LocationStep(location: $location)            // Step 3
                        .tag(3)
                    EquipmentStep(...)                           // Step 4
                        .tag(4)
                    CoachStep(llmProvider: $llmProvider, ...)    // Step 5
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Next / Back / Get Started buttons
            }
        }
    }
}
```

**Onboarding Steps:**

| Step | Purpose | Data Collected |
|------|---------|----------------|
| 0 | Welcome | Name |
| 1 | Goals | Goal (strength/hypertrophy), Units |
| 2 | Schedule | Days per week, Split type |
| 3 | Location | Gym vs Home |
| 4 | Equipment | Available gear |
| 5 | AI Coach | LLM provider, API keys, RPE familiarity |

### Readiness Check Sheet

**File:** `Views/Home/ReadinessCheckSheet.swift`

Pre-workout check-in.

```swift
struct ReadinessCheckSheet: View {
    @State private var energy: EnergyLevel = .ok
    @State private var soreness: SorenessLevel = .none
    @State private var timeAvailable: Int = 60
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Quick Check-in")
                    .font(.title.bold())
                
                // Energy selector (Low / OK / High)
                EnergySelector(selection: $energy)
                
                // Soreness selector (None / Mild / High)
                SorenessSelector(selection: $soreness)
                
                // Time picker (30 / 45 / 60 / 75 min)
                TimePicker(selection: $timeAvailable)
                
                // Adjustment preview if needed
                if energy == .low || soreness == .high {
                    Text("Intensity will be reduced")
                }
                
                Button("Let's Go") {
                    onStart(Readiness(
                        energy: energy, 
                        soreness: soreness, 
                        timeAvailable: timeAvailable
                    ))
                }
            }
        }
        .presentationDetents([.large])
    }
}
```

### Workout View

**File:** `Views/Workout/WorkoutView.swift`

Active workout logging interface.

```swift
struct WorkoutView: View {
    let template: WorkoutTemplate
    let plan: TodayPlanResponse?
    
    @State private var currentExerciseIndex = 0
    @State private var exerciseSets: [UUID: [WorkoutSet]] = [:]
    @State private var showRestTimer = false
    @State private var showSummary = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                WorkoutProgressBar(
                    currentExercise: currentExerciseIndex + 1,
                    totalExercises: totalExercises
                )
                
                if let exercise = currentExercise {
                    ScrollView {
                        VStack(spacing: 20) {
                            ExerciseHeader(exercise: exercise)
                            
                            SetsList(
                                sets: exerciseSets[exercise.id] ?? [],
                                onSetCompleted: { set in completeSet(set) },
                                onAddSet: { addSet() }
                            )
                            
                            ExerciseNavigation(
                                onBack: { currentExerciseIndex -= 1 },
                                onNext: { currentExerciseIndex += 1 },
                                onFinish: { showSummary = true }
                            )
                        }
                    }
                } else {
                    ContentUnavailableView("No Exercise", ...)
                }
            }
            .navigationTitle(template.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") { showSummary = true }
                }
            }
        }
    }
}
```

**Workout Components:**

| Component | Purpose |
|-----------|---------|
| `WorkoutProgressBar` | Exercise count + elapsed time |
| `ExerciseHeader` | Exercise name, muscles, tips |
| `SetsList` | Editable set rows |
| `SetRow` | Weight/reps/RPE input |
| `ExerciseNavigation` | Previous/Next/Finish buttons |
| `RestTimerSheet` | Countdown timer between sets |
| `WorkoutSummarySheet` | Post-workout review |

---

## Reusable Components

### Filter Chips

```swift
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
```

### Readiness Buttons

```swift
struct ReadinessButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

### Set Row

```swift
struct SetRow: View {
    @Binding var set: WorkoutSet
    let showRPE: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            // Set type indicator
            SetTypeBadge(type: set.setType)
            
            // Weight input
            TextField("Weight", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 60)
            
            Text("×")
            
            // Reps input
            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .frame(width: 40)
            
            // RPE input (optional)
            if showRPE {
                Text("@")
                TextField("RPE", value: $set.rpe, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 40)
            }
            
            Spacer()
            
            // Complete button
            Button(action: onComplete) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
        }
    }
}
```

---

## State Management

### Query-based State

SwiftData `@Query` for reactive data:

```swift
// Sorted queries
@Query(sort: \WorkoutTemplate.dayNumber) 
private var templates: [WorkoutTemplate]

// Reverse chronological
@Query(sort: \WorkoutSession.date, order: .reverse) 
private var sessions: [WorkoutSession]
```

### Local State

SwiftUI `@State` for UI state:

```swift
@State private var showSheet = false
@State private var selectedItem: Item?
@State private var searchText = ""
```

### Bindable Models

SwiftData `@Bindable` for two-way model binding:

```swift
struct TemplateEditorView: View {
    @Bindable var template: WorkoutTemplate
    
    var body: some View {
        TextField("Name", text: $template.name)  // Direct binding
    }
}
```

### Environment

Model context from environment:

```swift
@Environment(\.modelContext) private var modelContext
@Environment(\.dismiss) private var dismiss
```

---

## See Also

- [Architecture](ARCHITECTURE.md) - System design
- [Data Models](DATA_MODELS.md) - Entity structures
- [Agent System](AGENT_SYSTEM.md) - AI coaching
