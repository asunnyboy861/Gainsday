import Foundation
import SwiftData
import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var session: WorkoutSession?
    @Published var selectedExercise: Exercise?
    @Published var draftWeight: Double = 45
    @Published var draftReps: Int = 8
    @Published var celebration: String?
    @Published var isPR = false
    @Published var suggestion: OverloadSuggestion?
    @Published var restEndDate: Date?
    @Published var showPlateCalc = false
    @Published var showAddExercise = false
    @Published var showNLLogging = false
    @Published var welcomeBack: String?
    @Published var aiExplanation: String?
    @Published var lastSetBaseline: (weight: Double, reps: Int)?
    @Published var endedSummary: (volume: Double, delta: Double)?

    private var lastEntriesForExercise: [SetEntry] = []

    var restRemaining: Int {
        guard let end = restEndDate else { return 0 }
        return max(0, Int(end.timeIntervalSinceNow.rounded()))
    }

    func loadSession(context: ModelContext) {
        WatchSyncService.shared.onLogSet = { [weak self] exerciseName, weight, reps in
            guard let self, let session = self.session else { return }
            let exercise = self.selectedExercise?.name == exerciseName
                ? self.selectedExercise
                : self.findExercise(named: exerciseName, context: context)
            guard let exercise else { return }
            let entry = SetEntry(weight: weight, reps: reps, exercise: exercise, session: session)
            context.insert(entry)
            try? context.save()
            self.draftWeight = weight
            self.draftReps = reps
            self.celebration = "Logged from watch ⌚️"
        }
        if let session { syncWorkoutToWatch(); SnapshotStore.refresh(context: context); return }
        let predicate = #Predicate<WorkoutSession> { $0.deletedAt == nil }
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        let sessions = (try? context.fetch(descriptor)) ?? []
        let cal = Calendar.current
        if let today = sessions.first(where: { cal.isDateInToday($0.date) }) {
            session = today
        } else {
            let newSession = WorkoutSession(name: Self.defaultName(for: sessions.first))
            context.insert(newSession)
            try? context.save()
            session = newSession
        }
        checkWelcomeBack(sessions: sessions)
        syncWorkoutToWatch()
    }

    private static func defaultName(for last: WorkoutSession?) -> String {
        guard let last else { return "Workout A" }
        return last.name.hasSuffix("A") ? "Workout B" : "Workout A"
    }

    private func checkWelcomeBack(sessions: [WorkoutSession]) {
        guard let last = sessions.first else { return }
        let gap = DayKey.daysBetween(last.date, .now)
        if gap >= 14 {
            welcomeBack = "Welcome back 💪 You only lost a little. Let's get it back in 2 weeks."
        }
    }

    func exercisesInSession() -> [Exercise] {
        var seen = Set<String>()
        var result: [Exercise] = []
        for entry in (session?.entries ?? []).sorted(by: { $0.createdAt < $1.createdAt }) {
            if let ex = entry.exercise, !seen.contains(ex.id) {
                seen.insert(ex.id)
                result.append(ex)
            }
        }
        return result
    }

    func select(_ exercise: Exercise, context: ModelContext) {
        selectedExercise = exercise
        let exerciseID = exercise.id
        let predicate = #Predicate<SetEntry> { $0.exercise?.id == exerciseID && $0.session?.deletedAt == nil }
        let descriptor = FetchDescriptor<SetEntry>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let history = (try? context.fetch(descriptor)) ?? []
        lastEntriesForExercise = Array(history.dropFirst().prefix(50))
        if let last = history.first {
            let gapDays = DayKey.daysBetween(last.createdAt, .now)
            if gapDays >= 14 {
                draftWeight = max(45, (last.weight * 0.9).rounded())
                draftReps = last.reps
            } else {
                draftWeight = last.weight
                draftReps = last.reps
            }
            lastSetBaseline = (last.weight, last.reps)
        } else {
            draftWeight = 45
            draftReps = 8
            lastSetBaseline = nil
        }
        aiExplanation = nil
        suggestion = history.first.map { OverloadEngine.suggestNext(last: $0, isLowerBody: exercise.isLowerBody) }
        syncWorkoutToWatch()
    }

    private func findExercise(named name: String, context: ModelContext) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        let all = (try? context.fetch(descriptor)) ?? []
        return all.first { $0.name == name } ?? all.first { $0.name.localizedCaseInsensitiveContains(name) }
    }

    private func syncWorkoutToWatch() {
        guard let exercise = selectedExercise else { return }
        WatchSyncService.shared.sendWorkoutContext(
            name: session?.name ?? "Workout",
            exerciseName: exercise.name,
            lastWeight: draftWeight,
            lastReps: draftReps
        )
    }

    func tapWeight(context: ModelContext) {
        draftWeight += 5
    }

    func longPressWeight() {
        draftWeight = max(0, draftWeight - 2.5)
    }

    func tapReps() {
        draftReps += 1
    }

    func longPressReps() {
        draftReps = max(1, draftReps - 1)
    }

    func completeSet(context: ModelContext) {
        guard let session, let exercise = selectedExercise else { return }
        let entry = SetEntry(weight: draftWeight, reps: draftReps, exercise: exercise, session: session)
        context.insert(entry)
        try? context.save()

        let baseline = lastSetBaseline
        let pr = OverloadEngine.isPR(entry: entry, history: lastEntriesForExercise)
        isPR = pr
        if pr {
            celebration = "NEW PR 🏆"
        } else if let baseline {
            let diff = draftWeight - baseline.weight
            if diff > 0 {
                celebration = "+\(Int(diff)) lb vs last time 🔥"
            } else if diff == 0 && draftReps > baseline.reps {
                celebration = "Same weight, +\(draftReps - baseline.reps) reps 💪"
            } else if diff == 0 {
                celebration = "Same weight, clean reps. Strength is coming."
            } else {
                celebration = "Logged. Consistency wins."
            }
        } else {
            celebration = "First set logged 🔥"
        }

        lastEntriesForExercise.insert(entry, at: 0)
        if lastEntriesForExercise.count > 50 { lastEntriesForExercise.removeLast() }
        suggestion = OverloadEngine.suggestNext(last: entry, isLowerBody: exercise.isLowerBody)
        lastSetBaseline = (draftWeight, draftReps)

        startRestTimer()
        SnapshotStore.refresh(context: context)
        Task { await HealthKitService.shared.writeWorkout(session: session) }
        syncWorkoutToWatch()
    }

    func startRestTimer(seconds: Int = 120) {
        restEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        WatchSyncService.shared.sendRestTimer(seconds: seconds)
    }

    func extendRest() {
        guard restEndDate != nil else { return }
        startRestTimer(seconds: 30)
    }

    func endRest() {
        restEndDate = nil
    }

    func applySuggestion() {
        guard let s = suggestion else { return }
        draftWeight = s.weight
        draftReps = s.reps
    }

    func explainWithAI() {
        guard let s = suggestion, let ex = selectedExercise else { return }
        aiExplanation = "Thinking…"
        Task {
            let text = try? await AIRouter.shared.generateText(
                prompt: "A rule engine suggested this for \(ex.name): \(s.reason). Explain in 1-2 friendly sentences why this progression works.",
                system: "You are an encouraging strength coach. Plain American English."
            )
            aiExplanation = text ?? "Your body adapts when you push slightly past last time — that's progressive overload."
        }
    }

    func endWorkout(context: ModelContext) {
        guard let session else { return }
        let cal = Calendar.current
        let predicate = #Predicate<WorkoutSession> { $0.deletedAt == nil }
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        let all = (try? context.fetch(descriptor)) ?? []
        let prev = all.first { !cal.isDateInToday($0.date) && $0.name == session.name }
        let delta = OverloadEngine.volumeDelta(current: session.entries, previous: prev?.entries ?? [])
        endedSummary = (session.totalVolume, delta)
    }

    func parseNaturalLanguage(_ text: String, context: ModelContext) async -> String {
        let exerciseDescriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        let all = (try? context.fetch(exerciseDescriptor)) ?? []
        if #available(iOS 26.0, *) {
            if let draft = try? await AppleIntelligenceService.parseLogCommand(text) {
                let matched = all.first { $0.name.lowercased().contains(draft.exercise.lowercased()) }
                    ?? all.first { draft.exercise.lowercased().contains($0.name.lowercased().split(separator: " ").first.map(String.init) ?? "zzz") }
                let ex = matched ?? Exercise(id: "custom-\(draft.exercise)", name: draft.exercise, isCustom: true)
                if matched == nil { context.insert(ex) }
                selectedExercise = ex
                draftWeight = draft.weight
                draftReps = draft.reps
                return "Parsed: \(ex.name), \(draft.sets) × \(draft.reps) @ \(Int(draft.weight)) lb. Tap ✓ to log."
            }
        }
        if let byo = AIConfiguration.loadBYO() {
            do {
                let raw = try await CloudAIService(config: byo).generateText(
                    prompt: text,
                    system: "Parse workout commands into strict JSON {\"exercise\": string, \"sets\": int, \"reps\": int, \"weight\": number}. Reply ONLY with JSON."
                )
                guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"),
                      let data = String(raw[start...end]).data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let exName = obj["exercise"] as? String else {
                    return "Could not parse that. Try: bench 3 sets of 8 at 135"
                }
                let matched = all.first { $0.name.lowercased().contains(exName.lowercased()) }
                let ex = matched ?? Exercise(id: "custom-\(exName)", name: exName, isCustom: true)
                if matched == nil { context.insert(ex) }
                selectedExercise = ex
                draftWeight = (obj["weight"] as? NSNumber)?.doubleValue ?? 45
                draftReps = obj["reps"] as? Int ?? 8
                return "Parsed: \(ex.name). Tap ✓ to log."
            } catch {
                return error.localizedDescription
            }
        }
        return "Natural language logging needs Apple Intelligence (iOS 26+) or your own API key."
    }
}
