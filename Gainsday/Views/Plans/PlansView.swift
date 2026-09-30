import SwiftUI
import SwiftData

struct PlansView: View {
    @Query(sort: \Plan.createdAt) private var plans: [Plan]
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            if plans.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No plans yet")
                            .font(.headline)
                        Text("Classic beginner plans (A/B full-body and Push/Pull/Legs) ship with onboarding. You can also just log freestyle in Today — plans are optional.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Add Classic Beginner Plans") {
                            ExerciseDBSeeder.seedPlans(context: context)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            ForEach(plans, id: \.persistentModelID) { plan in
                Section(plan.name) {
                    ForEach(plan.days.sorted { $0.sortOrder < $1.sortOrder }, id: \.persistentModelID) { day in
                        NavigationLink {
                            PlanDayDetailView(day: day, planName: plan.name)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(day.name).font(.headline)
                                Text(day.exerciseNames.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Plans")
    }
}

struct PlanDayDetailView: View {
    let day: PlanDay
    let planName: String
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    private func match(_ name: String) -> Exercise? {
        exercises.first { $0.name == name } ?? exercises.first { $0.name.localizedCaseInsensitiveContains(name) }
    }

    var body: some View {
        List {
            ForEach(day.exerciseNames, id: \.self) { name in
                if let ex = match(name) {
                    NavigationLink {
                        ExerciseDetailView(exercise: ex)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.name)
                            Text("\(ex.primaryMuscles.joined(separator: ", ").capitalized) — log it freestyle in Today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text(name)
                }
            }
        }
        .navigationTitle("\(planName) — \(day.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
