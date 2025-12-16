# Changelog

All notable changes to Strength Tracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-16

### Added

#### Core Features
- **Smart Workout Logging** - Quick set entry with weight, reps, and RPE tracking
- **Auto-populated targets** - Next set suggestions based on workout history
- **Rest timer** - Configurable countdown between sets
- **Warmup generation** - Automatic warmup sets with collapsible display
- **Workout swap** - Switch to different workouts from home screen

#### Exercise Library
- **100+ exercises** covering all major movement patterns
- **Kettlebell exercises** - Swings, goblet squats, Turkish get-ups
- **Resistance band exercises** - Pull-aparts, face pulls, band squats
- **Cardio exercises** - Treadmill, bike, rowing, battle ropes, jump rope
- **Carry exercises** - Farmer walks, suitcase carry, overhead carry
- **Pre-workout mobility** - Cat-cow, world's greatest stretch, hip circles
- **Post-workout stretches** - Pigeon pose, couch stretch, foam rolling
- **Form guidance** - Interactive tips with cues and common mistakes

#### AI-Powered Coaching
- **Intelligent progression** - Optimal weight/rep targets per session
- **Readiness adaptation** - Intensity adjusted based on energy, soreness, time
- **Custom workout generation** - Create workouts from natural language
- **Stall detection** - Plateau identification with fix suggestions
- **Post-workout insights** - AI-generated actionable feedback
- **Weekly AI review** - Comprehensive analysis with recommendations
- **Multiple LLM providers** - Support for Claude, OpenAI, or offline engine

#### Progress Tracking
- **Interactive charts** - Tap and drag to inspect e1RM trend data
- **Estimated 1RM tracking** - Strength gains via Epley formula
- **Volume analytics** - Weekly/daily aggregated volume charts
- **Recent PRs** - Automatic personal record detection
- **Training calendar** - Monthly view with workout frequency heatmap
- **Streak tracking** - Current streak, longest streak, monthly count
- **Muscle group breakdown** - Volume distribution visualization
- **Three-tab layout** - Overview, Lifts, and Calendar views

#### Equipment Flexibility
- **Location profiles** - Gym vs home equipment configurations
- **Smart substitutions** - Automatic exercise swaps based on gear
- **Pain flag handling** - Flag exercises and get alternatives

#### Settings & Customization
- **Appearance mode** - Light, dark, or system automatic theme
- **Unit system** - Support for metric and imperial units
- **Profile management** - Complete user profile configuration

### Technical
- SwiftUI with iOS 17+ features
- SwiftData for persistence
- MVVM architecture with @Observable
- Comprehensive test suite (11 unit test files, 5 UI test files)
- CI/CD with GitHub Actions

## [Unreleased]

### Planned
- Apple Watch companion app
- HealthKit integration
- Social features and workout sharing
- Exercise video demonstrations
- Custom exercise creation

---

[1.0.0]: https://github.com/shtarun/strength-tracker/releases/tag/v1.0.0
[Unreleased]: https://github.com/shtarun/strength-tracker/compare/v1.0.0...HEAD
