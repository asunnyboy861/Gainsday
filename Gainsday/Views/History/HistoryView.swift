import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WorkoutSession> { $0.deletedAt == nil },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    var body: some View {
        List {
            ForEach(sessions, id: \.persistentModelID) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.name).font(.headline)
                            Spacer()
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            Label("\(session.entries.count) sets", systemImage: "square.stack.3d.up")
                            Label("\(Int(session.totalVolume).formatted()) lb", systemImage: "scalemass")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        session.deletedAt = .now
                        try? context.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("History")
        .overlay {
            if sessions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.orange)
                    Text("No workouts yet")
                        .font(.headline)
                    Text("Your logged sessions will appear here — and stay editable, always.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    @State private var editingEntry: SetEntry?
    @State private var editWeight: Double = 45
    @State private var editReps: Int = 8
    @State private var confirmDelete = false

    private var sortedEntries: [SetEntry] {
        session.entries.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                TextField("Workout name", text: $session.name)
                    .font(.headline)
                TextField("Notes", text: $session.notes, axis: .vertical)
                    .lineLimit(2...5)
            }
            Section("Sets") {
                ForEach(sortedEntries, id: \.persistentModelID) { entry in
                    Button {
                        editWeight = entry.weight
                        editReps = entry.reps
                        editingEntry = entry
                    } label: {
                        HStack {
                            Text(entry.exercise?.name ?? "Custom")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(Int(entry.weight)) lb × \(entry.reps)")
                                .foregroundStyle(.secondary)
                            if entry.editedAt > entry.createdAt.addingTimeInterval(60) {
                                Image(systemName: "pencil")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.gold)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(entry)
                            try? context.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            Section {
                HStack {
                    Text("Total volume")
                    Spacer()
                    Text("\(Int(session.totalVolume).formatted()) lb")
                        .foregroundStyle(Theme.orange)
                }
            } footer: {
                Text("Everything here stays editable. Fixed a weight wrong? Tap the set and correct it — the pencil mark keeps the audit trail honest.")
            }
        }
        .navigationTitle(session.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                session.deletedAt = .now
                try? context.save()
            }
        }
        .sheet(item: $editingEntry) { entry in
            editSheet(entry)
        }
    }

    private func editSheet(_ entry: SetEntry) -> some View {
        NavigationStack {
            Form {
                Text(entry.exercise?.name ?? "Custom")
                    .font(.headline)
                Stepper("Weight: \(Int(editWeight)) lb", value: Binding(
                    get: { editWeight },
                    set: { editWeight = max(0, ($0 / 2.5).rounded() * 2.5) }
                ), in: 0...1000, step: 2.5)
                Stepper("Reps: \(editReps)", value: $editReps, in: 1...100)
                Button("Save Changes") {
                    entry.weight = editWeight
                    entry.reps = editReps
                    entry.editedAt = .now
                    try? context.save()
                    editingEntry = nil
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
        }
    }
}
