import Foundation
import Security

enum KeychainHelper {
    static func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveString(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(data, service: service, account: account)
    }

    static func readString(service: String, account: String) -> String? {
        guard let data = read(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

struct ProviderProfile: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let defaultBaseURL: String
    let defaultModel: String
    let supportsVision: Bool
    let note: String

    static let all: [ProviderProfile] = [
        ProviderProfile(id: "glm", displayName: "GLM (Z.ai)",
                        defaultBaseURL: "https://api.z.ai/api/paas/v4/chat/completions",
                        defaultModel: "glm-4.6v", supportsVision: true,
                        note: "Vision-capable. Recommended for the AI Form Coach."),
        ProviderProfile(id: "openai", displayName: "GPT Series",
                        defaultBaseURL: "https://api.openai.com/v1/chat/completions",
                        defaultModel: "gpt-4o-mini", supportsVision: true,
                        note: "Use gpt-4o or newer for photo analysis."),
        ProviderProfile(id: "gemini", displayName: "Google Gemini",
                        defaultBaseURL: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
                        defaultModel: "gemini-2.0-flash", supportsVision: true,
                        note: "Standard chat completions endpoint."),
        ProviderProfile(id: "deepseek", displayName: "DeepSeek",
                        defaultBaseURL: "https://api.deepseek.com/chat/completions",
                        defaultModel: "deepseek-chat", supportsVision: false,
                        note: "Text tasks only (no vision)."),
        ProviderProfile(id: "claude", displayName: "Claude",
                        defaultBaseURL: "https://api.anthropic.com/v1/chat/completions",
                        defaultModel: "claude-sonnet-4-5", supportsVision: true,
                        note: "Standard chat completions endpoint."),
        ProviderProfile(id: "custom", displayName: "Custom / Any Provider",
                        defaultBaseURL: "", defaultModel: "", supportsVision: true,
                        note: "Any endpoint that speaks the standard chat completions format.")
    ]
}

struct AIKeyConfig: Codable, Hashable {
    var providerID: String
    var apiKey: String
    var baseURL: String
    var model: String

    var resolvedProfile: ProviderProfile? {
        ProviderProfile.all.first { $0.id == providerID }
    }

    var supportsVision: Bool {
        resolvedProfile?.supportsVision ?? true
    }
}

enum AIConfiguration {
    static let keychainService = "com.zzoutuo.Gainsday.ai"
    static let keychainAccount = "byo.key"
    static let defaultsKey = "ai.byo.config"

    static func saveBYO(_ config: AIKeyConfig) {
        KeychainHelper.saveString(config.apiKey, service: keychainService, account: keychainAccount)
        if let data = try? JSONEncoder().encode(config),
           let json = String(data: data, encoding: .utf8) {
            KeychainHelper.saveString(json, service: keychainService, account: "byo.meta")
        }
    }

    static func loadBYO() -> AIKeyConfig? {
        guard let json = KeychainHelper.readString(service: keychainService, account: "byo.meta"),
              let data = json.data(using: .utf8),
              let config = try? JSONDecoder().decode(AIKeyConfig.self, from: data) else { return nil }
        guard let key = KeychainHelper.readString(service: keychainService, account: keychainAccount),
              !key.isEmpty else { return nil }
        return AIKeyConfig(providerID: config.providerID, apiKey: key,
                           baseURL: config.baseURL, model: config.model)
    }

    static func deleteBYO() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
        KeychainHelper.delete(service: keychainService, account: "byo.meta")
    }

    static var hasAPIKey: Bool { loadBYO() != nil }
}
