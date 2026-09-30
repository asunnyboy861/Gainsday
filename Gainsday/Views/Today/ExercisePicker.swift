import SwiftUI
import SwiftData

struct ExercisePicker: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var query = ""
    var onPick: (Exercise) -> Void

    private var filtered: [Exercise] {
        guard !query.isEmpty else { return allExercises }
        return allExercises.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.primaryMuscles.joined().localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.persistentModelID) { ex in
                Button {
                    onPick(ex)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        if !ex.primaryMuscles.isEmpty {
                            Text(ex.primaryMuscles.joined(separator: ", ").capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search 800+ exercises")
            .navigationTitle("Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
