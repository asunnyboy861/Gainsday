import Foundation

final class CloudAIService: LanguageAIService, VisionAIService {
    let config: AIKeyConfig
    var providerLabel: String { config.resolvedProfile?.displayName ?? "Custom" }

    init(config: AIKeyConfig) {
        self.config = config
    }

    private func request(path: String? = nil) -> URLRequest {
        let url = URL(string: config.baseURL.isEmpty
            ? (config.resolvedProfile?.defaultBaseURL ?? "")
            : config.baseURL) ?? URL(string: "https://api.z.ai/api/paas/v4/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 12
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        return req
    }

    private func send(body: [String: Any]) async throws -> String {
        var req = request()
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw AIServiceError.requestFailed("Network error: \(error.localizedDescription)")
        }
        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 401, 403:
                throw AIServiceError.requestFailed("Key rejected (HTTP \(http.statusCode)). Check your API key.")
            case 429:
                throw AIServiceError.requestFailed("Rate limited. Try again shortly.")
            default:
                let text = String(data: data, encoding: .utf8) ?? ""
                throw AIServiceError.requestFailed("HTTP \(http.statusCode). \(text.prefix(120))")
            }
        }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String, !content.isEmpty else {
            throw AIServiceError.invalidResponse
        }
        return content
    }

    func generateText(prompt: String, system: String) async throws -> String {
        let body: [String: Any] = [
            "model": config.model.isEmpty ? (config.resolvedProfile?.defaultModel ?? "") : config.model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4,
            "max_tokens": 400
        ]
        return try await send(body: body)
    }

    func analyzeForm(frameJPEG: Data, exerciseName: String) async throws -> FormFeedback {
        let b64 = frameJPEG.base64EncodedString()
        let system = """
        You are a strength coach reviewing ONE gym photo (side view of a lift).
        Compare body joint alignment against textbook form for: \(exerciseName).
        Reply ONLY as JSON: {"good":[string], "fix":[string], "cue":"string <=12 words", "risk":"low|medium|high"}
        Be concrete about joints (knees, hips, spine). Never invent what you cannot see.
        """
        let body: [String: Any] = [
            "model": config.model.isEmpty ? (config.resolvedProfile?.defaultModel ?? "") : config.model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": [
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]],
                    ["type": "text", "text": "Check this form."]
                ]]
            ],
            "temperature": 0.3,
            "max_tokens": 400
        ]
        let content = try await send(body: body)
        return try Self.decodeFeedback(from: content)
    }

    static func decodeFeedback(from content: String) throws -> FormFeedback {
        let trimmed = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}") else {
            throw AIServiceError.invalidResponse
        }
        let jsonText = String(trimmed[start...end])
        guard let data = jsonText.data(using: .utf8),
              var feedback = try? JSONDecoder().decode(FormFeedback.self, from: data) else {
            throw AIServiceError.invalidResponse
        }
        if feedback.good.isEmpty && feedback.fix.isEmpty && feedback.cue.isEmpty {
            throw AIServiceError.invalidResponse
        }
        if feedback.risk.isEmpty { feedback = FormFeedback(good: feedback.good, fix: feedback.fix, cue: feedback.cue, risk: "unknown") }
        return feedback
    }
}
