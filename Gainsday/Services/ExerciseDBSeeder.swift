import Foundation
import SwiftData

enum ExerciseDBSeeder {
    private struct RawExercise: Decodable {
        let name: String
        let force: String?
        let level: String?
        let mechanic: String?
        let equipment: String?
        let primaryMuscles: [String]?
        let secondaryMuscles: [String]?
        let instructions: [String]?
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard existing == 0 else { return }
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        guard let raws = try? decoder.decode([RawExercise].self, from: data) else { return }
        for raw in raws {
            let ex = Exercise(
                id: raw.name,
                name: raw.name,
                equipment: raw.equipment ?? "",
                level: raw.level ?? "",
                mechanic: raw.mechanic ?? "",
                primaryMuscles: raw.primaryMuscles ?? [],
                secondaryMuscles: raw.secondaryMuscles ?? [],
                instructions: raw.instructions ?? []
            )
            context.insert(ex)
        }
        try? context.save()
    }

    @MainActor
    static func seedPlans(context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Plan>())) ?? 0
        guard existing == 0 else { return }
        let available = Set((try? context.fetch(FetchDescriptor<Exercise>()))?.map(\.name) ?? [])

        func resolve(_ names: [String]) -> [String] {
            names.map { name in
                if available.contains(name) { return name }
                return available.first { $0.localizedCaseInsensitiveContains(name) } ?? name
            }
        }

        let classic = Plan(name: "Classic Beginner A/B")
        for (index, day) in planA.enumerated() {
            classic.days.append(PlanDay(name: day.0, sortOrder: index, exerciseNames: resolve(day.1)))
        }
        context.insert(classic)

        let ppl = Plan(name: "Push / Pull / Legs")
        for (index, day) in planB.enumerated() {
            ppl.days.append(PlanDay(name: day.0, sortOrder: index, exerciseNames: resolve(day.1)))
        }
        context.insert(ppl)
        try? context.save()
    }

    static let planA = [
        ("Workout A", ["Barbell Squat", "Barbell Bench Press", "Barbell Row"]),
        ("Workout B", ["Barbell Deadlift", "Standing Overhead Barbell Press", "Pull up"])
    ]
    static let planB = [
        ("Push Day", ["Barbell Bench Press", "Incline Dumbbell Press", "Standing Overhead Barbell Press"]),
        ("Pull Day", ["Pull up", "Barbell Row", "Dumbbell Biceps Curl"]),
        ("Leg Day", ["Barbell Squat", "Romanian Deadlift", "Standing Calf Raise"])
    ]
}
