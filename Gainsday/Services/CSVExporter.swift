import Foundation

enum CSVExporter {
    static func export(entries: [SetEntry]) -> String {
        var rows: [String] = ["date,exercise,weight_lb,reps,rpe"]
        let sorted = entries.sorted { $0.createdAt < $1.createdAt }
        let formatter = ISO8601DateFormatter()
        for e in sorted {
            let name = (e.exercise?.name ?? "Custom").replacingOccurrences(of: ",", with: " ")
            rows.append("\(formatter.string(from: e.createdAt)),\(name),\(e.weight),\(e.reps),\(e.rpe)")
        }
        return rows.joined(separator: "\n")
    }

    static func fileName() -> String {
        "Gainsday-export-\(DayKey.key(for: .now)).csv"
    }
}
