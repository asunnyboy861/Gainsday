import Foundation
import SwiftUI
import SwiftData

enum SnapshotStore {
    static let suiteName = "group.com.zzoutuo.Gainsday"

    @MainActor
    static func refresh(context: ModelContext) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let sessions = (try? context.fetch(sessionDescriptor)) ?? []
        let cal = Calendar.current
        let todaySets = sessions.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.entries.count }
        let todayVolume = sessions.filter { cal.isDateInToday($0.date) }.reduce(0.0) { $0 + $1.totalVolume }

        var weekSetCounts: [String: Int] = [:]
        for session in sessions {
            let key = "\(DayKey.weekYear(for: session.date))-\(DayKey.weekIndex(for: session.date))"
            weekSetCounts[key, default: 0] += 1
        }
        var streakWeeks = 0
        var cursor = Date()
        for _ in 0..<12 {
            let key = "\(DayKey.weekYear(for: cursor))-\(DayKey.weekIndex(for: cursor))"
            if (weekSetCounts[key] ?? 0) > 0 {
                streakWeeks += 1
                cursor = cal.date(byAdding: .day, value: -7, to: cursor) ?? cursor
            } else if streakWeeks == 0 {
                cursor = cal.date(byAdding: .day, value: -7, to: cursor) ?? cursor
            } else {
                break
            }
        }

        defaults.set(todaySets, forKey: "snapshot.todaySets")
        defaults.set(todayVolume, forKey: "snapshot.todayVolume")
        defaults.set(streakWeeks, forKey: "snapshot.streakWeeks")
        defaults.set(Date().timeIntervalSince1970, forKey: "snapshot.updatedAt")
    }
}
