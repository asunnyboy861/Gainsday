import SwiftUI
import SwiftData

@main
struct GainsdayApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Exercise.self, WorkoutSession.self, SetEntry.self, ProgressPhoto.self, Plan.self, PlanDay.self])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            container = try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .tint(Theme.orange)
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var purchaseManager = PurchaseManager.shared
    @State private var sync = WatchSyncService.shared

    var body: some View {
        Group {
            if onboardingDone {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            ExerciseDBSeeder.seedIfNeeded(context: modelContext)
            QuotaStore.shared.resetIfNewMonth()
            WeeklyRecapScheduler.shared.scheduleIfNeeded(context: modelContext)
        }
    }
}
