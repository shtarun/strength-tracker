# Strength Tracker

An AI-powered iOS strength training app for intermediate lifters. Log workouts fast, get intelligent next-session recommendations, and adapt to your equipment and readiness.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![SwiftData](https://img.shields.io/badge/SwiftData-✓-purple)

## Features

### 🏋️ Smart Workout Logging
- **Quick set entry** - Log weight, reps, and RPE with minimal taps
- **Auto-populated targets** - Next set suggestions based on your history
- **Rest timer** - Configurable countdown between sets
- **Warmup generation** - Automatic warmup sets calculated from your working weight

### 🤖 AI-Powered Coaching
- **Intelligent progression** - Calculates optimal weight/rep targets for each session
- **Readiness adaptation** - Adjusts intensity based on energy, soreness, and time
- **Stall detection** - Identifies plateaus and suggests fixes (deloads, rep range changes, variations)
- **Post-workout insights** - Actionable feedback after each session

### 📊 Progress Tracking
- **Estimated 1RM tracking** - See strength gains over time using the Epley formula
- **Volume analytics** - Track weekly sets per muscle group
- **Workout history** - Review past sessions and performance trends

### 🔧 Equipment Flexibility
- **Location profiles** - Gym vs home equipment configurations
- **Smart substitutions** - Automatic exercise swaps based on available gear
- **Pain flag handling** - Avoid exercises that aggravate injuries

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/strength-tracker.git
   cd strength-tracker
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
│   ├── LLMService.swift   # Provider manager
│   ├── ClaudeProvider.swift
│   ├── OpenAIProvider.swift
│   └── OfflineProgressionEngine.swift
├── Services/               # Business logic
│   ├── ExerciseLibrary.swift
│   ├── TemplateGenerator.swift
│   └── SubstitutionGraph.swift
└── Utilities/              # Helper functions
    ├── E1RMCalculator.swift
    └── PlateMathCalculator.swift
```

## Requirements

- **Xcode 15+**
- **iOS 17+**
- **Swift 5.9+**

## Testing

Run the test suite from Xcode:

```bash
# Run all tests
⌘+U in Xcode

# Or via command line
xcodebuild test -scheme StrengthTracker -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Coverage

| Test File | Coverage |
|-----------|----------|
| `E1RMCalculatorTests.swift` | e1RM calculations, Epley/Brzycki formulas |
| `PlateMathCalculatorTests.swift` | Plate loading, warmup generation |
| `ModelTests.swift` | SwiftData entities, relationships, computed properties |
| `OfflineProgressionEngineTests.swift` | Progression rules, stall detection, insights |
| `SubstitutionGraphTests.swift` | Exercise substitutions, equipment filtering |
| `LLMServiceTests.swift` | Context building, response parsing |

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
