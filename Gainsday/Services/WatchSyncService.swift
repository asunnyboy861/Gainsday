import Foundation
import WatchConnectivity

final class WatchSyncService: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSyncService()
    var onLogSet: ((String, Double, Int) -> Void)?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message["action"] as? String == "logSet" else { return }
        let exercise = message["exercise"] as? String ?? ""
        let weight = message["weight"] as? Double ?? 0
        let reps = message["reps"] as? Int ?? 0
        DispatchQueue.main.async {
            self.onLogSet?(exercise, weight, reps)
        }
    }

    func sendRestTimer(seconds: Int) {
        guard WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext([
            "action": "restTimer",
            "endsAt": Date().addingTimeInterval(TimeInterval(seconds)).timeIntervalSince1970
        ])
    }

    func sendWorkoutContext(name: String, exerciseName: String, lastWeight: Double, lastReps: Int) {
        guard WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext([
            "action": "workout",
            "name": name,
            "exercise": exerciseName,
            "lastWeight": lastWeight,
            "lastReps": lastReps
        ])
    }
}
