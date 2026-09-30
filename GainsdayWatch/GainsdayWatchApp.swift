import SwiftUI
import WatchConnectivity

final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var workoutName = "Gainsday"
    @Published var exerciseName = "Open the iPhone app"
    @Published var lastWeight: Double = 45
    @Published var lastReps: Int = 8
    @Published var draftWeight: Double = 45
    @Published var draftReps: Int = 8
    @Published var restEnd: Date?
    @Published var confirmation: String?

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            apply(context: session.receivedApplicationContext)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.apply(context: applicationContext) }
    }

    private func apply(context: [String: Any]) {
        guard let action = context["action"] as? String else { return }
        switch action {
        case "workout":
            workoutName = context["name"] as? String ?? workoutName
            exerciseName = context["exercise"] as? String ?? exerciseName
            lastWeight = context["lastWeight"] as? Double ?? lastWeight
            lastReps = context["lastReps"] as? Int ?? lastReps
            if draftWeight != lastWeight || draftReps != lastReps {
                draftWeight = lastWeight
                draftReps = lastReps
            }
        case "restTimer":
            let endsAt = context["endsAt"] as? TimeInterval ?? 0
            restEnd = Date(timeIntervalSince1970: endsAt)
        default:
            break
        }
    }

    func tapWeight() { draftWeight += 5 }
    func longPressWeight() { draftWeight = max(0, draftWeight - 2.5) }
    func tapReps() { draftReps += 1 }
    func longPressReps() { draftReps = max(1, draftReps - 1) }

    func logSet() {
        guard WCSession.default.isReachable else {
            confirmation = "iPhone not reachable"
            return
        }
        WCSession.default.sendMessage([
            "action": "logSet",
            "exercise": exerciseName,
            "weight": draftWeight,
            "reps": draftReps
        ], replyHandler: nil) { [weak self] _ in
            DispatchQueue.main.async { self?.confirmation = "Could not reach iPhone" }
        }
        confirmation = "Logged \(Int(draftWeight)) lb × \(draftReps) 🔥"
    }
}

struct WatchHomeView: View {
    @StateObject private var model = WatchModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    if let end = model.restEnd {
                        restCard(end: end)
                    }
                    VStack(spacing: 2) {
                        Text(model.exerciseName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text(model.workoutName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        cell(value: "\(Int(model.draftWeight))", unit: "LB", tint: .orange,
                             tap: { model.tapWeight() }, longPress: { model.longPressWeight() })
                        cell(value: "\(model.draftReps)", unit: "REPS", tint: .cyan,
                             tap: { model.tapReps() }, longPress: { model.longPressReps() })
                    }
                    Button {
                        model.logSet()
                    } label: {
                        Label("Log Set", systemImage: "checkmark")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    if let note = model.confirmation {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 2)
            }
            .navigationTitle("Gainsday")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func restCard(end: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let remaining = max(0, Int(end.timeIntervalSince(timeline.date).rounded()))
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text(remaining > 0
                     ? String(format: "%d:%02d", remaining / 60, remaining % 60)
                     : "Go!")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(.orange.opacity(0.15)))
        }
    }

    private func cell(value: String, unit: String, tint: Color, tap: @escaping () -> Void, longPress: @escaping () -> Void) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold))
                .contentTransition(.numericText())
            Text(unit)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.18)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(tint.opacity(0.4), lineWidth: 1))
        .onTapGesture {
            withAnimation(.spring(duration: 0.3)) { tap() }
        }
        .onLongPressGesture {
            withAnimation(.spring(duration: 0.3)) { longPress() }
        }
    }
}

@main
struct GainsdayWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
