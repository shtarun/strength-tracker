import Foundation

enum LLMProviderType: String, Codable, CaseIterable, Identifiable {
    case claude = "Claude"
    case openai = "OpenAI"
    case offline = "Offline"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude (Anthropic)"
        case .openai: return "ChatGPT (OpenAI)"
        case .offline: return "Offline Mode"
        }
    }

    var icon: String {
        switch self {
        case .claude: return "brain.head.profile"
        case .openai: return "sparkles"
        case .offline: return "wifi.slash"
        }
    }

    var requiresAPIKey: Bool {
        self != .offline
    }

    var apiKeyPlaceholder: String {
        switch self {
        case .claude: return "sk-ant-..."
        case .openai: return "sk-..."
        case .offline: return ""
        }
    }
}
