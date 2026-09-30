import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleIntelligenceService {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }

    static func generateText(prompt: String, system: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: system)
            let response = try await session.respond(to: prompt)
            return response.content
        }
        #endif
        throw AIServiceError.notConfigured
    }

    static func parseLogCommand(_ text: String) async throws -> ParsedSetDraft {
        let system = "Parse workout commands into strict JSON {\"exercise\": string, \"sets\": int, \"reps\": int, \"weight\": number}. Reply ONLY with JSON, no other text."
        let raw = try await generateText(prompt: text, system: system)
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"),
              let data = String(raw[start...end]).data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exercise = obj["exercise"] as? String else {
            throw AIServiceError.invalidResponse
        }
        let sets = obj["sets"] as? Int ?? 1
        let reps = obj["reps"] as? Int ?? 8
        let weight = (obj["weight"] as? Double) ?? (obj["weight"] as? NSNumber)?.doubleValue ?? 45
        return ParsedSetDraft(exercise: exercise, sets: sets, reps: reps, weight: weight)
    }

    static func weeklyRecap(volumeDelta: Double, prCount: Int) async -> String {
        let prompt = "This week total volume \(volumeDelta >= 0 ? "+" : "")\(Int(volumeDelta))%, \(prCount) new PRs. Write the user's weekly recap."
        let system = "You are an encouraging gym coach. Max 2 sentences. No emoji spam."
        if let text = try? await generateText(prompt: prompt, system: system) {
            return text
        }
        return "Stronger than last week. Keep going."
    }

    static func explainSuggestion(_ reason: String, exercise: String) async -> String {
        let prompt = "A rule engine suggested this for \(exercise): \(reason). Explain in 1-2 friendly sentences why this progression works for a lifter."
        let system = "You are an encouraging strength coach. Plain American English."
        if let text = try? await generateText(prompt: prompt, system: system) {
            return text
        }
        return reason
    }
}
