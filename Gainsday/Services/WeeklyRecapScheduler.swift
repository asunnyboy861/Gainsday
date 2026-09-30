import Foundation
import UserNotifications
import SwiftData
import SwiftUI

@MainActor
final class WeeklyRecapScheduler: ObservableObject {
    static let shared = WeeklyRecapScheduler()
    private let center = UNUserNotificationCenter.current()

    func scheduleIfNeeded(context: ModelContext) {
        Task {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                await scheduleNextMonday()
            case .notDetermined:
                let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                if granted { await scheduleNextMonday() }
            default:
                break
            }
        }
    }

    private func scheduleNextMonday() async {
        center.removePendingNotificationRequests(withIdentifiers: ["gainsday.weekly.recap"])
        guard let nextMonday = nextMonday8AM() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your weekly recap is ready 💪"
        content.body = "See how much stronger you got this week."
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextMonday)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "gainsday.weekly.recap", content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func nextMonday8AM() -> Date? {
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        for _ in 0..<8 {
            date = cal.date(byAdding: .day, value: 1, to: date) ?? date
            if cal.component(.weekday, from: date) == 2 {
                return cal.date(bySettingHour: 8, minute: 0, second: 0, of: date)
            }
        }
        return nil
    }
}

struct WeeklyRecapCard: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]
    @State private var recap: String?
    @State private var loading = false

    private var active: [WorkoutSession] {
        sessions.filter { $0.deletedAt == nil }
    }

    private var thisWeek: [WorkoutSession] {
        active.filter { DayKey.daysBetween($0.date, .now) < 7 }
    }

    private var lastWeek: [WorkoutSession] {
        active.filter { let d = DayKey.daysBetween($0.date, .now); return d >= 7 && d < 14 }
    }

    private var localSummary: String {
        let tv = thisWeek.reduce(0.0) { $0 + $1.totalVolume }
        let lv = lastWeek.reduce(0.0) { $0 + $1.totalVolume }
        let sets = thisWeek.reduce(0) { $0 + $1.entries.count }
        guard !thisWeek.isEmpty else {
            return "No sessions this week yet. Today is a great Gainsday to start."
        }
        guard !lastWeek.isEmpty else {
            return "\(thisWeek.count) session\(thisWeek.count == 1 ? "" : "s"), \(sets) sets, \(Int(tv).formatted()) lb total volume logged."
        }
        let pct = lv > 0 ? Int(((tv - lv) / lv) * 100) : 100
        let direction = pct >= 0 ? "up" : "down"
        return "\(thisWeek.count) sessions, \(sets) sets. Volume \(direction) \(abs(pct))% vs last week."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Weekly Recap", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                if !loading {
                    Button {
                        generate()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Regenerate recap")
                }
            }
            if loading {
                ProgressView()
            } else {
                Text(recap ?? localSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task { if recap == nil { generate() } }
    }

    private func generate() {
        loading = true
        Task {
            let prompt = """
            Write a 1-2 sentence encouraging weekly strength recap. This week: \(thisWeek.count) sessions, \
            \(thisWeek.reduce(0) { $0 + $1.entries.count }) sets, \(Int(thisWeek.reduce(0.0) { $0 + $1.totalVolume })) lb volume. \
            Last week: \(lastWeek.count) sessions, \(Int(lastWeek.reduce(0.0) { $0 + $1.totalVolume })) lb volume. \
            Frame progress positively even if flat.
            """
            recap = try? await AIRouter.shared.generateText(prompt: prompt, system: "You are a warm, concise strength coach. Plain American English.")
            loading = false
        }
    }
}
