import WidgetKit
import SwiftUI

private let suiteName = "group.com.zzoutuo.Gainsday"

struct GainsdayEntry: TimelineEntry {
    let date: Date
    let todaySets: Int
    let todayVolume: Double
    let streakWeeks: Int
    let trainedKeys: [String]
}

struct GainsdayProvider: TimelineProvider {
    private static let calendarFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func placeholder(in context: Context) -> GainsdayEntry {
        GainsdayEntry(date: .now, todaySets: 9, todayVolume: 4320, streakWeeks: 3, trainedKeys: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (GainsdayEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GainsdayEntry>) -> Void) {
        let entry = makeEntry()
        let nextMidnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: entry.date) ?? entry.date)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func makeEntry() -> GainsdayEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        let sets = defaults?.integer(forKey: "snapshot.todaySets") ?? 0
        let volume = defaults?.double(forKey: "snapshot.todayVolume") ?? 0
        let streak = defaults?.integer(forKey: "snapshot.streakWeeks") ?? 0
        var keys: [String] = []
        if let recents = defaults?.stringArray(forKey: "snapshot.recentDays") {
            keys = recents
        }
        return GainsdayEntry(date: .now, todaySets: sets, todayVolume: volume, streakWeeks: streak, trainedKeys: keys)
    }
}

struct GainsdayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: GainsdayProvider.Entry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.todaySets)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("SETS")
                        .font(.system(size: 9, weight: .bold))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("Gainsday")
                    .font(.headline)
                Text("\(entry.todaySets) sets · \(Int(entry.todayVolume).formatted()) lb")
                    .font(.caption2)
                Text("🔥 \(entry.streakWeeks) week streak")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Gainsday")
                        .font(.headline)
                    Spacer()
                    Text("🔥 \(entry.streakWeeks)w")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                if family == .systemLarge {
                    miniGrid
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.todaySets > 0
                         ? "\(entry.todaySets) sets · \(Int(entry.todayVolume).formatted()) lb today"
                         : "No sets yet — every day is Gainsday.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(4)
        }
    }

    private var miniGrid: some View {
        let trained = Set(entry.trainedKeys)
        let cal = Calendar.current
        let today = cal.startOfDay(for: entry.date)
        let firstCell = cal.date(byAdding: .day, value: -27, to: today) ?? today
        let firstWeekStart = cal.dateInterval(of: .weekOfYear, for: firstCell)?.start ?? firstCell
        func key(for date: Date) -> String {
            let comps = cal.dateComponents([.year, .month, .day], from: date)
            return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
        }
        return VStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { col in
                        if let cell = cal.date(byAdding: .day, value: row * 7 + col, to: firstWeekStart), cell <= today {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(trained.contains(key(for: cell)) ? Color.orange : Color.secondary.opacity(0.25))
                                .frame(height: 10)
                        } else {
                            Color.clear.frame(height: 10)
                        }
                    }
                }
            }
        }
    }
}

struct GainsdayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GainsdayWidget", provider: GainsdayProvider()) { entry in
            GainsdayWidgetView(entry: entry)
        }
        .configurationDisplayName("Gainsday")
        .description("Today's sets, volume, and your streak — gold days never lie.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct GainsdayWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GainsdayWidget()
    }
}
