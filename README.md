# Strength Tracker

An AI-powered iOS strength training app for intermediate lifters. Log workouts fast, get intelligent next-session recommendations, and adapt to your equipment and readiness.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![SwiftData](https://img.shields.io/badge/SwiftData-✓-purple)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### 🏋️ Smart Workout Logging
- **Quick set entry** - Log weight, reps, and RPE with minimal taps
- **Auto-populated targets** - Next set suggestions based on your history
- **Rest timer** - Configurable countdown between sets
- **Warmup generation** - Automatic warmup sets with collapsible display
- **Workout swap** - Easily switch to a different workout from the home screen

### 🏃 Comprehensive Exercise Library
- **100+ exercises** - Covering all major movement patterns
- **Kettlebell exercises** - Swings, goblet squats, Turkish get-ups, and more
- **Resistance band exercises** - Pull-aparts, face pulls, band squats, etc.
- **Cardio exercises** - Treadmill, bike, rowing, battle ropes, jump rope
- **Carry exercises** - Farmer walks, suitcase carry, overhead carry, rack carry
- **Pre-workout mobility** - Cat-cow, world's greatest stretch, hip circles
- **Post-workout stretches** - Pigeon pose, couch stretch, foam rolling routines
- **Form guidance** - Interactive form tips with cues and common mistakes for each exercise

### 🤖 AI-Powered Coaching
- **Intelligent progression** - Calculates optimal weight/rep targets for each session
- **Readiness adaptation** - Adjusts intensity based on energy, soreness, and time available
- **Custom workout generation** - Create workouts from natural language (e.g., "Upper push for 30 min")
- **Stall detection** - Identifies plateaus and suggests fixes (deloads, rep range changes, variations)
- **Post-workout insights** - AI-generated actionable feedback after each session
- **Weekly AI review** - Comprehensive analysis with consistency score, highlights, and recommendations
- **Multiple LLM providers** - Support for Claude, OpenAI, or offline rule-based engine

### 📊 Progress Tracking
- **Interactive charts** - Tap and drag to inspect data points on e1RM trend lines
- **Estimated 1RM tracking** - See strength gains over time using the Epley formula
- **Volume analytics** - Weekly/daily aggregated volume charts with session stats
- **Recent PRs** - Personal record tracking with automatic detection
- **Training calendar** - Monthly view with workout frequency heatmap
- **Streak tracking** - Current streak, longest streak, and monthly workout count
- **Muscle group breakdown** - Visual bars showing volume distribution by muscle
- **Three-tab layout** - Overview, Lifts, and Calendar views

### 🏠 Home Screen
- **Today's workout preview** - Expandable exercise list with prescription details
- **Workout swap** - Quick picker to switch to any other template
- **Custom workout** - AI-powered workout creation from natural language prompts
- **Quick stats** - Weekly workouts, current streak at a glance
- **Recent workouts** - Easy access to your workout history

### 🔧 Equipment Flexibility
- **Location profiles** - Gym vs home equipment configurations
- **Smart substitutions** - Automatic exercise swaps based on available gear
- **Pain flag handling** - Flag exercises that aggravate injuries and get alternatives

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/shtarun/strength-tracker.git
   cd strength-tracker/StrengthTracker
   ```

2. **Open in Xcode**
   ```bash
   open StrengthTracker/StrengthTracker.xcodeproj
   ```

3. **Build and run** (⌘+R)
   - Target: iOS 17+ Simulator or device

4. **Complete onboarding**
   - Enter your name and training preferences
   - Configure your equipment profile
   - Optionally add an LLM API key for enhanced AI features

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | System design, patterns, and component overview |
| [Data Models](docs/DATA_MODELS.md) | SwiftData entities and relationships |
| [Agent System](docs/AGENT_SYSTEM.md) | AI coaching engine and LLM integration |
| [Views & UI](docs/VIEWS.md) | Screen structure and navigation flow |
| [Progression Logic](docs/PROGRESSION.md) | Training science and programming rules |
| [API Reference](docs/API_REFERENCE.md) | LLM provider protocols and response formats |
| [Developer Guide](docs/DEVELOPER_GUIDE.md) | Development setup and coding conventions |
| [Plan Compliance](docs/PLAN_COMPLIANCE.md) | Implementation audit against original plan |
| [Testing](docs/TESTING.md) | Comprehensive test documentation and coverage |
| [**Changelog**](CHANGELOG.md) | **Version history and release notes** |

## Technology Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Architecture | MVVM |
| State Management | @Observable, @Query |
| AI Integration | Claude API, OpenAI API |
| Offline Fallback | Rule-based progression engine |

## Project Structure

```
StrengthTracker/
├── App/                    # App entry point and main views
│   ├── StrengthTrackerApp.swift
│   └── ContentView.swift
├── Models/                 # SwiftData entities
│   ├── UserProfile.swift
│   ├── EquipmentProfile.swift
│   ├── Exercise.swift
│   ├── WorkoutTemplate.swift
│   ├── WorkoutSession.swift
│   ├── WorkoutSet.swift
│   ├── PainFlag.swift
│   └── Enums/             # Supporting enumerations
├── Views/                  # SwiftUI views
│   ├── Home/              # Dashboard and workout start
│   ├── Workout/           # Active workout logging
│   ├── Templates/         # Workout template management
│   ├── Progress/          # Analytics and history
│   ├── Profile/           # Settings and preferences
│   ├── Onboarding/        # First-run setup
│   └── Exercise/          # Exercise details
├── Agent/                  # AI coaching system
│   ├── LLMService.swift   # Provider manager & response types
│   ├── ClaudeProvider.swift
│   ├── OpenAIProvider.swift
│   └── OfflineProgressionEngine.swift
├── Services/               # Business logic
│   ├── ExerciseLibrary.swift
│   ├── TemplateGenerator.swift
│   ├── SubstitutionGraph.swift
│   └── StallDetector.swift # Plateau detection & suggestions
└── Utilities/              # Helper functions
    ├── E1RMCalculator.swift
    └── PlateMathCalculator.swift
```

## Readiness System

The app adapts your workout based on how you feel:

| Input | Condition | Effect |
|-------|-----------|--------|
| **Energy** | Low | RPE capped at 7.5, fewer backoff sets |
| **Soreness** | High | RPE capped at 7.5, reduced volume |
| **Energy + Soreness** | High + None | RPE cap +0.5, extra backoff set |
| **Time** | ≤45 min | Optional exercises skipped |

## Requirements

- **Xcode 15+**
- **iOS 17+**
- **Swift 5.9+**

## Testing

The project uses a standard iOS two-folder test architecture:

| Folder | Framework | Purpose |
|--------|-----------|---------|
| `StrengthTrackerTests/` | XCTest | Unit tests (fast, isolated) |
| `StrengthTrackerUITests/` | XCUITest | UI tests (user flow integration) |

This separation is **iOS best practice** because:
- Unit tests run in milliseconds and are ideal for CI/every-commit testing
- UI tests run in seconds and simulate actual user interactions on simulators/devices

### Running Tests

```bash
# Run all tests
xcodebuild test -project StrengthTracker.xcodeproj \
  -scheme StrengthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Run only unit tests (fast)
xcodebuild test -only-testing:StrengthTrackerTests ...

# Run only UI tests
xcodebuild test -only-testing:StrengthTrackerUITests ...

# Or in Xcode: ⌘+U
```

### Test Coverage

| Test Category | Files | Description |
|--------------|-------|-------------|
| **Unit Tests** | 11 | Models, enums, calculators, services |
| **UI Tests** | 5 | Onboarding, workout, profile, progress, templates |

**Key test suites:**

| Suite | Coverage |
|-------|----------|
| `E1RMCalculatorTests` | e1RM calculations, Epley formula |
| `PlateMathCalculatorTests` | Plate loading, warmup generation |
| `ModelTests` | SwiftData entities, enums, computed properties |
| `WorkoutSessionTests` | Sessions, sets, readiness, e1RM |
| `StallDetectorTests` | Plateau detection, fix suggestions |
| `TemplateGeneratorTests` | Workout templates, prescriptions |
| `UserProfileTests` | Profile, appearance mode, API keys |
| `OnboardingUITests` | Full onboarding flow |
| `WorkoutFlowUITests` | Workout logging user journey |

📖 **See [Testing Documentation](docs/TESTING.md) for detailed test descriptions, examples, and CI/CD setup.**

## Optional: LLM API Keys

For enhanced AI coaching, you can configure API keys during onboarding or in Settings:

- **Claude (Anthropic)** - Recommended for best results
- **OpenAI** - GPT-4 compatible

The app works fully offline with the built-in rule-based progression engine.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Training methodology inspired by evidence-based strength training principles
- Built with Apple's latest SwiftUI and SwiftData frameworks
- AI coaching powered by Claude and OpenAI
