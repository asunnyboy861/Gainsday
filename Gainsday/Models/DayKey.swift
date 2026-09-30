import Foundation

enum DayKey {
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    static func date(forKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func weekIndex(for date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.weekOfYear, from: date)
    }

    static func weekYear(for date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.yearForWeekOfYear, from: date)
    }

    static func daysBetween(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: a), to: calendar.startOfDay(for: b)).day ?? 0
    }
}
