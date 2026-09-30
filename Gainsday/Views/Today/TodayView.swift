import SwiftUI
import SwiftData

struct BigCell: View {
    let value: String
    let unit: String
    let tint: Color
    var onTap: () -> Void
    var onLongPress: (() -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(40))
                .contentTransition(.numericText())
            Text(unit)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            withAnimation(.spring(duration: 0.4)) { onTap() }
        }
        .onLongPressGesture {
            withAnimation(.spring(duration: 0.4)) { onLongPress?() }
        }
        .accessibilityLabel("\(unit): \(value). Tap to increase.")
    }
}

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = TodayViewModel()
    @State private var nlText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let welcome = viewModel.welcomeBack {
                        welcomeBackCard(welcome)
                    }
                    if let session = viewModel.session {
                        sessionHeader(session)
                        exerciseStrip
                        if viewModel.selectedExercise != nil {
                            loggingGrid
                            if let s = viewModel.suggestion { suggestionCard(s) }
                        } else {
                            emptyState
                        }
                        restTimerCard
                        endWorkoutButton
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.charcoal)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showNLLogging = true
                    } label: {
                        Image(systemName: "text.bubble")
                    }
                    .accessibilityLabel("Log with natural language")
                }
            }
            .sheet(isPresented: $viewModel.showPlateCalc) { plateCalcSheet }
            .sheet(isPresented: $viewModel.showAddExercise) { addExerciseSheet }
            .sheet(isPresented: $viewModel.showNLLogging) { nlSheet }
            .sensoryFeedback(.success, trigger: viewModel.celebration)
            .task { viewModel.loadSession(context: context) }
            .overlay(alignment: .top) { celebrationOverlay }
        }
    }

    private var celebrationOverlay: some View {
        Group {
            if let c = viewModel.celebration {
                Text(c)
                    .font(Theme.rounded(22))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(viewModel.isPR ? Theme.gold : Theme.orange))
                    .foregroundStyle(.white)
                    .shadow(radius: 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: viewModel.celebration)
        .onChange(of: viewModel.celebration) { _, newValue in
            guard newValue != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                viewModel.celebration = nil
            }
        }
    }

    private func welcomeBackCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text).font(.headline)
            Text("Starting a bit lighter today — prefilled -10%.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sessionHeader(_ session: WorkoutSession) -> some View {
        HStack {
            Text("Continue: \(session.name)")
                .font(.headline)
            Spacer()
            Text("\(session.entries.count) sets")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var exerciseStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.exercisesInSession(), id: \.persistentModelID) { ex in
                    Button {
                        viewModel.select(ex, context: context)
                    } label: {
                        Text(ex.name)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(viewModel.selectedExercise?.id == ex.id ? Theme.orange : Theme.surface)
                            )
                            .foregroundStyle(viewModel.selectedExercise?.id == ex.id ? .white : .primary)
                    }
                }
                Button {
                    viewModel.showAddExercise = true
                } label: {
                    Image(systemName: "plus")
                        .padding(10)
                        .background(Circle().fill(Theme.surface))
                }
                .accessibilityLabel("Add exercise")
            }
        }
    }

    private var loggingGrid: some View {
        VStack(spacing: 12) {
            if let ex = viewModel.selectedExercise {
                HStack {
                    Text(ex.name).font(.title3.weight(.semibold))
                    Spacer()
                    if let baseline = viewModel.lastSetBaseline {
                        Text("Last: \(Int(baseline.weight)) lb × \(baseline.reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            HStack(spacing: 12) {
                BigCell(value: "\(Int(viewModel.draftWeight))", unit: "LB", tint: Theme.orange,
                        onTap: { viewModel.tapWeight(context: context) },
                        onLongPress: { viewModel.longPressWeight(); viewModel.showPlateCalc = true })
                BigCell(value: "\(viewModel.draftReps)", unit: "REPS", tint: Theme.cyan,
                        onTap: { viewModel.tapReps() },
                        onLongPress: { viewModel.longPressReps() })
                Button {
                    withAnimation { viewModel.completeSet(context: context) }
                } label: {
                    Image(systemName: "checkmark")
                        .font(Theme.rounded(32))
                        .foregroundStyle(.white)
                        .frame(width: 84, height: 84)
                        .background(Circle().fill(Color.green.gradient))
                }
                .accessibilityLabel("Complete set")
            }
            Button("Plate calculator") {
                viewModel.showPlateCalc = true
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func suggestionCard(_ s: OverloadSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Next time", systemImage: "arrow.up.right")
                    .font(.headline)
                Spacer()
                Button("Apply") { viewModel.applySuggestion() }
                    .font(.caption.weight(.semibold))
            }
            Text("\(Int(s.weight)) lb × \(s.reps)")
                .font(Theme.rounded(28))
                .foregroundStyle(Theme.gold)
            Text(s.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("Why?") { viewModel.explainWithAI() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.orange)
                if let explanation = viewModel.aiExplanation {
                    Text(explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var restTimerCard: some View {
        Group {
            if let end = viewModel.restEndDate {
                HStack(spacing: 16) {
                    Text("Rest")
                        .font(.headline)
                    Spacer()
                    Text(timeString(until: end))
                        .font(Theme.rounded(34, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.orange)
                    Button("+30s") { viewModel.extendRest() }
                        .font(.caption.weight(.semibold))
                    Button("Skip") { viewModel.endRest() }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var endWorkoutButton: some View {
        Button {
            viewModel.endWorkout(context: context)
        } label: {
            Text("Finish Workout")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.orange)
            Text("Add an exercise to start logging")
                .font(.headline)
            Text("Tap the numbers to change weight, ✓ to log. That's it.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Add Exercise") { viewModel.showAddExercise = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var plateCalcSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("\(Int(viewModel.draftWeight)) lb")
                    .font(Theme.rounded(48))
                Text("Per side: \(PlateCalculator.label(total: viewModel.draftWeight))")
                    .font(.title3)
                    .foregroundStyle(Theme.orange)
                HStack {
                    Button("-2.5 lb") { viewModel.longPressWeight() }
                    Button("+5 lb") { viewModel.tapWeight(context: context) }
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding()
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var addExerciseSheet: some View {
        ExercisePicker { exercise in
            viewModel.selectedExercise = exercise
            viewModel.select(exercise, context: context)
        }
    }

    private var nlSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Try: bench 3 sets of 8 at 135")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Your workout command", text: $nlText)
                    .textFieldStyle(.roundedBorder)
                Button("Parse") {
                    Task {
                        let result = await viewModel.parseNaturalLanguage(nlText, context: context)
                        viewModel.celebration = result
                        viewModel.showNLLogging = false
                        nlText = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("Quick Log")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private func timeString(until end: Date) -> String {
        let remaining = max(0, Int(end.timeIntervalSinceNow.rounded()))
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }
}
