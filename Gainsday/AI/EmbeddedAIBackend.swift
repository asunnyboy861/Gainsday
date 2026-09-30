import Foundation

enum EmbeddedAIBackend {
    struct Profile {
        let apiKey: String
        let endpointURL: String
        let modelID: String
    }

    static func loadProfiles() -> [Profile] {
        guard let url = Bundle.main.url(forResource: "GLMSecret", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.allLines
            .filter { !$0.hasPrefix("#") }
            .compactMap { line -> Profile? in
                let parts = line.split(separator: "|").map(String.init)
                guard parts.count == 3, !parts[0].isEmpty else { return nil }
                return Profile(apiKey: parts[0], endpointURL: parts[1], modelID: parts[2])
            }
    }

    static var isConfigured: Bool { !loadProfiles().isEmpty }

    static func service() -> CloudAIService? {
        guard let profile = loadProfiles().first else { return nil }
        let config = AIKeyConfig(providerID: "glm", apiKey: profile.apiKey,
                                 baseURL: profile.endpointURL, model: profile.modelID)
        return CloudAIService(config: config)
    }
}

private extension String {
    var allLines: [String] {
        self.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
