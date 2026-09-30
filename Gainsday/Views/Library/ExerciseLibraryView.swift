import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var query = ""
    @State private var equipmentFilter = "All"
    @State private var muscleFilter = "All"

    private static let muscles = ["All", "Chest", "Upper Back", "Lats", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Abs", "Forearms"]

    private var equipmentOptions: [String] {
        var set = Set<String>()
        for ex in exercises where !ex.equipment.isEmpty { set.insert(ex.equipment) }
        return ["All"] + set.sorted()
    }

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesQuery = query.isEmpty ||
                ex.name.localizedCaseInsensitiveContains(query) ||
                ex.primaryMuscles.joined().localizedCaseInsensitiveContains(query)
            let matchesEquipment = equipmentFilter == "All" || ex.equipment == equipmentFilter
            let matchesMuscle = muscleFilter == "All" ||
                ex.primaryMuscles.contains { $0.localizedCaseInsensitiveCompare(muscleFilter) == .orderedSame }
            return matchesQuery && matchesEquipment && matchesMuscle
        }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(equipmentOptions, id: \.self) { option in
                                Button(option) { equipmentFilter = option }
                            }
                        } label: {
                            Label(equipmentFilter == "All" ? "Equipment" : equipmentFilter, systemImage: "slider.horizontal.3")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(equipmentFilter == "All" ? Theme.surface : Theme.orange))
                                .foregroundStyle(equipmentFilter == "All" ? Color.primary : Color.white)
                        }
                        ForEach(Self.muscles, id: \.self) { muscle in
                            Button {
                                muscleFilter = muscle
                            } label: {
                                Text(muscle)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(muscleFilter == muscle ? Theme.orange : Theme.surface))
                                    .foregroundStyle(muscleFilter == muscle ? .white : .primary)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            ForEach(filtered.prefix(120), id: \.persistentModelID) { ex in
                NavigationLink {
                    ExerciseDetailView(exercise: ex)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                        HStack(spacing: 8) {
                            if !ex.equipment.isEmpty { Text(ex.equipment.capitalized) }
                            if !ex.level.isEmpty { Text(ex.level.capitalized) }
                            if !ex.primaryMuscles.isEmpty { Text(ex.primaryMuscles.joined(separator: ", ").capitalized) }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            if filtered.count > 120 {
                Section {
                    Text("Showing 120 of \(filtered.count) matches — refine your filters to see more.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $query, prompt: "Search \(exercises.count) exercises")
        .navigationTitle("Exercises")
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    if !exercise.equipment.isEmpty {
                        tag(exercise.equipment.capitalized, tint: Theme.orange)
                    }
                    if !exercise.level.isEmpty {
                        tag(exercise.level.capitalized, tint: Theme.cyan)
                    }
                    if !exercise.mechanic.isEmpty {
                        tag(exercise.mechanic.capitalized, tint: .secondary)
                    }
                }
                if !exercise.primaryMuscles.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Primary Muscles").font(.headline)
                        Text(exercise.primaryMuscles.joined(separator: ", ").capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if !exercise.secondaryMuscles.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Secondary Muscles").font(.headline)
                        Text(exercise.secondaryMuscles.joined(separator: ", ").capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if !exercise.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How To").font(.headline)
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(idx + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(Theme.orange))
                                Text(step)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .background(Theme.charcoal)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.18)))
            .foregroundStyle(tint == .secondary ? .secondary : tint)
    }
}
