import SwiftUI
import SwiftData
import Charts

struct ProgressHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WorkoutSession> { $0.deletedAt == nil },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    @State private var chartExercise: Exercise?
    @State private var showExercisePicker = false

    private var recentSessions: [WorkoutSession] {
        sessions.filter { DayKey.daysBetween($0.date, .now) <= 84 }
    }

    private var streakWeeks: Int {
        var weeks: Set<String> = []
        for s in recentSessions {
            weeks.insert("\(DayKey.weekYear(for: s.date))-\(DayKey.weekIndex(for: s.date))")
        }
        var streak = 0
        var cursor = Date()
        while streak < 12 {
            let key = "\(DayKey.weekYear(for: cursor))-\(DayKey.weekIndex(for: cursor))"
            if weeks.contains(key) {
                streak += 1
                cursor = Calendar.current.date(byAdding: .day, value: -7, to: cursor) ?? cursor
            } else if streak == 0 {
                cursor = Calendar.current.date(byAdding: .day, value: -7, to: cursor) ?? cursor
                let prevKey = "\(DayKey.weekYear(for: cursor))-\(DayKey.weekIndex(for: cursor))"
                if weeks.contains(prevKey) { streak = 1 } else { break }
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WeeklyRecapCard()
                    strengthCurveCard
                    calendarCard
                    if purchaseManager.isPro {
                        statsCard
                    } else {
                        proStatsTeaser
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.charcoal)
            .navigationTitle("Progress")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePicker { chartExercise = $0 }
            }
        }
    }

    private var strengthCurveCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Your Strength Curve", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                Spacer()
                Button(chartExercise?.name ?? "Pick exercise") {
                    showExercisePicker = true
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.orange)
            }
            if let ex = chartExercise {
                let points = strengthPoints(for: ex)
                if points.isEmpty {
                    Text("Log a few sets of \(ex.name) to see your curve.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    Chart(points, id: \.date) { point in
                        LineMark(x: .value("Date", point.date), y: .value("1RM", point.estimate))
                            .foregroundStyle(Theme.orange)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", point.date), y: .value("1RM", point.estimate))
                            .foregroundStyle(Theme.gold)
                    }
                    .chartYAxisLabel("Estimated 1RM (lb)")
                    .frame(height: 200)
                    Text("Best estimated 1RM: \(Int(points.map(\.estimate).max() ?? 0)) lb")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("One line, only up and to the right. Pick a lift to see how far you've come.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private struct StrengthPoint { let date: Date; let estimate: Double }

    private func strengthPoints(for exercise: Exercise) -> [StrengthPoint] {
        var best: [String: StrengthPoint] = [:]
        for session in sessions {
            for entry in session.entries where entry.exercise?.id == exercise.id {
                let estimate = OverloadEngine.estimate1RM(weight: entry.weight, reps: entry.reps)
                let key = DayKey.key(for: entry.createdAt)
                if let existing = best[key] {
                    if estimate > existing.estimate {
                        best[key] = StrengthPoint(date: entry.createdAt, estimate: estimate)
                    }
                } else {
                    best[key] = StrengthPoint(date: entry.createdAt, estimate: estimate)
                }
            }
        }
        return best.values.sorted { $0.date < $1.date }
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your Gainsdays", systemImage: "calendar")
                .font(.headline)
            calendarGrid
            HStack(spacing: 4) {
                Text("🔥 \(streakWeeks) week streak. Keep the grid glowing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var calendarGrid: some View {
        let trained = Set(recentSessions.map { DayKey.key(for: $0.date) })
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let firstCell = cal.date(byAdding: .day, value: -83, to: today) ?? today
        let firstWeekStart = cal.dateInterval(of: .weekOfYear, for: firstCell)?.start ?? firstCell
        return VStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { col in
                        if let cell = cal.date(byAdding: .day, value: row * 7 + col, to: firstWeekStart) {
                            let key = DayKey.key(for: cell)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(trained.contains(key) ? Theme.gold : Theme.charcoal.opacity(0.35))
                                .frame(height: 18)
                                .opacity(cell > today ? 0.25 : 1)
                        } else {
                            Color.clear.frame(height: 18)
                        }
                    }
                }
            }
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Advanced Stats", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(Theme.gold)
            HStack(spacing: 12) {
                statTile(value: "\(recentSessions.count)", label: "Sessions (12 wk)")
                statTile(value: "\(recentSessions.reduce(0) { $0 + $1.entries.count })", label: "Sets logged")
                statTile(value: "\(Int(recentSessions.reduce(0.0) { $0 + $1.totalVolume }).formatted())", label: "Total lb")
            }
        }
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(22))
                .foregroundStyle(Theme.gold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.charcoal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var proStatsTeaser: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Advanced Stats")
                        .font(.headline)
                    Text("Sessions, sets, and lifetime volume — unlock with Pro.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
