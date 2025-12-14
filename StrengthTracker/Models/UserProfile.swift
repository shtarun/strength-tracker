import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var goal: Goal
    var daysPerWeek: Int
    var preferredSplit: Split
    var rpeFamiliarity: Bool
    var defaultRestTime: Int // seconds
    var unitSystem: UnitSystem
    var preferredLLMProvider: LLMProviderType
    var claudeAPIKey: String?
    var openAIAPIKey: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var equipmentProfile: EquipmentProfile?

    init(
        id: UUID = UUID(),
        name: String = "",
        goal: Goal = .both,
        daysPerWeek: Int = 4,
        preferredSplit: Split = .upperLower,
        rpeFamiliarity: Bool = false,
        defaultRestTime: Int = 180,
        unitSystem: UnitSystem = .metric,
        preferredLLMProvider: LLMProviderType = .offline,
        claudeAPIKey: String? = nil,
        openAIAPIKey: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.goal = goal
        self.daysPerWeek = daysPerWeek
        self.preferredSplit = preferredSplit
        self.rpeFamiliarity = rpeFamiliarity
        self.defaultRestTime = defaultRestTime
        self.unitSystem = unitSystem
        self.preferredLLMProvider = preferredLLMProvider
        self.claudeAPIKey = claudeAPIKey
        self.openAIAPIKey = openAIAPIKey
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var activeAPIKey: String? {
        switch preferredLLMProvider {
        case .claude: return claudeAPIKey
        case .openai: return openAIAPIKey
        case .offline: return nil
        }
    }

    var hasValidAPIKey: Bool {
        guard let key = activeAPIKey else { return preferredLLMProvider == .offline }
        return !key.isEmpty
    }
}
