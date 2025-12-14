// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StrengthTracker",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "StrengthTracker",
            targets: ["StrengthTracker"]
        )
    ],
    targets: [
        .target(
            name: "StrengthTracker",
            dependencies: [],
            path: "StrengthTracker",
            exclude: [
                "App",
                "Assets.xcassets",
                "Preview Content"
            ],
            sources: [
                "Utilities/E1RMCalculator.swift",
                "Utilities/PlateMathCalculator.swift",
                "Models/Enums/Equipment.swift",
                "Models/Enums/Goal.swift",
                "Models/Enums/LLMProvider.swift",
                "Models/Enums/Location.swift",
                "Models/Enums/MovementPattern.swift",
                "Models/Enums/Muscle.swift",
                "Models/Enums/ProgressionType.swift",
                "Models/Enums/Readiness.swift",
                "Models/Enums/SetType.swift",
                "Models/Enums/Split.swift",
                "Models/Enums/UnitSystem.swift",
                "Models/EquipmentProfile.swift",
                "Models/Exercise.swift",
                "Models/PainFlag.swift",
                "Models/UserProfile.swift",
                "Models/WorkoutSession.swift",
                "Models/WorkoutSet.swift",
                "Models/WorkoutTemplate.swift",
                "Services/ExerciseLibrary.swift",
                "Services/SubstitutionGraph.swift",
                "Services/TemplateGenerator.swift",
                "Agent/ClaudeProvider.swift",
                "Agent/LLMService.swift",
                "Agent/OfflineProgressionEngine.swift",
                "Agent/OpenAIProvider.swift"
            ]
        ),
        .testTarget(
            name: "StrengthTrackerTests",
            dependencies: ["StrengthTracker"],
            path: "StrengthTrackerTests"
        )
    ]
)
