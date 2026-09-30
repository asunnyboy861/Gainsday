import Foundation

struct FormFeedback: Codable, Equatable {
    let good: [String]
    let fix: [String]
    let cue: String
    let risk: String

    static let empty = FormFeedback(good: [], fix: [], cue: "", risk: "unknown")
}

struct ParsedSetDraft: Equatable {
    var exercise: String
    var sets: Int
    var reps: Int
    var weight: Double
}

enum AIServiceError: LocalizedError {
    case notConfigured
    case quotaExhausted
    case requestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "No AI backend is available. Add your own API key in Settings."
        case .quotaExhausted: return "Monthly cloud quota reached. Add your own API key for unlimited use."
        case .requestFailed(let m): return m
        case .invalidResponse: return "The AI response could not be parsed."
        }
    }
}

protocol LanguageAIService {
    var providerLabel: String { get }
    func generateText(prompt: String, system: String) async throws -> String
}

protocol VisionAIService {
    var providerLabel: String { get }
    func analyzeForm(frameJPEG: Data, exerciseName: String) async throws -> FormFeedback
}
