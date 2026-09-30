import Foundation
import HealthKit
import SwiftUI

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    @AppStorage("healthkitEnabled") var enabled: Bool = false
    @Published var isAuthorized = false

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        let types: Set<HKSampleType> = [HKWorkoutType.workoutType()]
        do {
            try await store.requestAuthorization(toShare: types, read: [])
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    func writeWorkout(session: WorkoutSession) async {
        guard isAvailable, enabled, !session.entries.isEmpty else { return }
        let start = session.date
        let end = session.entries.map(\.createdAt).max() ?? start.addingTimeInterval(600)
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.addMetadata(["GainsdayVolume": session.totalVolume as NSNumber])
            try await builder.endCollection(at: end)
            try await builder.finishWorkout()
        } catch {
            return
        }
    }
}
