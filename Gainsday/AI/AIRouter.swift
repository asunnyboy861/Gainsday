import Foundation

@MainActor
final class AIRouter: ObservableObject {
    static let shared = AIRouter()

    @Published var lastProviderLabel: String = ""

    func hasOnDeviceAI() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }

    func canUseAI() -> Bool {
        hasOnDeviceAI() || AIConfiguration.hasAPIKey || QuotaStore.shared.canUseEmbedded
    }

    func generateText(prompt: String, system: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            lastProviderLabel = "Apple Intelligence"
            if let text = try? await AppleIntelligenceService.generateText(prompt: prompt, system: system) {
                return text
            }
        }
        #endif
        if let byo = AIConfiguration.loadBYO() {
            lastProviderLabel = byo.resolvedProfile?.displayName ?? "Custom"
            return try await CloudAIService(config: byo).generateText(prompt: prompt, system: system)
        }
        guard QuotaStore.shared.canUseEmbedded, let embedded = EmbeddedAIBackend.service() else {
            throw AIServiceError.notConfigured
        }
        lastProviderLabel = "Gainsday Cloud"
        let text = try await embedded.generateText(prompt: prompt, system: system)
        QuotaStore.shared.consume()
        return text
    }

    func analyzeForm(frameJPEG: Data, exerciseName: String) async throws -> (FormFeedback, Bool) {
        if let byo = AIConfiguration.loadBYO(), byo.supportsVision {
            lastProviderLabel = byo.resolvedProfile?.displayName ?? "Custom"
            let feedback = try await CloudAIService(config: byo).analyzeForm(frameJPEG: frameJPEG, exerciseName: exerciseName)
            return (feedback, false)
        }
        guard QuotaStore.shared.canUseEmbedded, let embedded = EmbeddedAIBackend.service() else {
            throw AIServiceError.notConfigured
        }
        lastProviderLabel = "Gainsday Cloud"
        let feedback = try await embedded.analyzeForm(frameJPEG: frameJPEG, exerciseName: exerciseName)
        QuotaStore.shared.consume()
        return (feedback, false)
    }
}
