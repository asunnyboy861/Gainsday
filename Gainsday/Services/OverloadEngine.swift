import Foundation

struct OverloadSuggestion: Equatable {
    let weight: Double
    let reps: Int
    let reason: String
}

enum OverloadEngine {
    static func suggestNext(last: SetEntry, isLowerBody: Bool) -> OverloadSuggestion {
        let inc = isLowerBody ? 10.0 : 5.0
        let targetReps = 8
        if last.reps >= targetReps {
            return OverloadSuggestion(
                weight: last.weight + inc,
                reps: targetReps,
                reason: "Last time you hit \(last.reps)/\(targetReps) reps — time to add \(Int(inc)) lb."
            )
        }
        if last.reps >= targetReps - 2 {
            let short = targetReps - last.reps
            return OverloadSuggestion(
                weight: last.weight,
                reps: min(targetReps, last.reps + 1),
                reason: "You were \(short) rep\(short == 1 ? "" : "s") short. Same weight, one more rep."
            )
        }
        let deload = (last.weight * 0.9).rounded()
        return OverloadSuggestion(
            weight: deload,
            reps: targetReps,
            reason: "That session was heavy. Dropping 10% to build momentum back."
        )
    }

    static func estimate1RM(weight: Double, reps: Int) -> Double {
        reps <= 1 ? weight : weight * (1 + Double(reps) / 30.0)
    }

    static func isPR(entry: SetEntry, history: [SetEntry]) -> Bool {
        guard let best = history.map({ estimate1RM(weight: $0.weight, reps: $0.reps) }).max() else {
            return false
        }
        return estimate1RM(weight: entry.weight, reps: entry.reps) > best
    }

    static func volumeDelta(current: [SetEntry], previous: [SetEntry]) -> Double {
        let cv = current.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        let pv = previous.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        guard pv > 0 else { return cv }
        return ((cv - pv) / pv) * 100
    }
}
