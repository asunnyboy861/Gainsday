import Foundation
import SwiftUI

@MainActor
final class AIProfileManager: ObservableObject {
    static let shared = AIProfileManager()

    @Published var byoConfig: AIKeyConfig?
    @Published var saveState: String = ""

    init() {
        byoConfig = AIConfiguration.loadBYO()
    }

    var hasAPIKey: Bool { byoConfig != nil }

    func save(providerID: String, apiKey: String, baseURL: String, model: String) {
        let profile = ProviderProfile.all.first { $0.id == providerID }
        let config = AIKeyConfig(
            providerID: providerID,
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? (profile?.defaultBaseURL ?? "") : baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? (profile?.defaultModel ?? "") : model.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard !config.apiKey.isEmpty else {
            saveState = "API key is required."
            return
        }
        AIConfiguration.saveBYO(config)
        byoConfig = config
        saveState = "Saved. Cloud AI is now unlimited on your own key."
    }

    func delete() {
        AIConfiguration.deleteBYO()
        byoConfig = nil
        saveState = "Key removed. On-device AI remains available."
    }

    func testConnection(_ config: AIKeyConfig) async -> String {
        do {
            let service = CloudAIService(config: config)
            _ = try await service.generateText(prompt: "Reply with the single word: ok.", system: "You are a connection test.")
            return "Connection OK."
        } catch {
            return "Failed: \(error.localizedDescription)"
        }
    }
}
