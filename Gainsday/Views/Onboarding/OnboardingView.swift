import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                brandPage.tag(0)
                choicePage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: page == 0 ? .always : .always))
            .animation(.spring(duration: 0.4), value: page)
        }
        .background(Theme.charcoal.ignoresSafeArea())
    }

    private var brandPage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.orange.gradient)
                    .frame(width: 130, height: 130)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
            }
            Text("Gainsday")
                .font(Theme.rounded(44))
                .foregroundStyle(Theme.gold)
            Text("Every day is Gainsday.")
                .font(.title3)
                .foregroundStyle(.primary)
            Text("Log a set in 2 taps, and we'll tell you exactly how to beat it next time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Button {
                withAnimation { page = 1 }
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
    }

    private var choicePage: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 24)
            Text("How do you want to train?")
                .font(Theme.rounded(28))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            featureRow(icon: "hand.tap.fill", tint: Theme.orange,
                       title: "2-Tap Logging",
                       detail: "Tap weight, tap reps, ✓. Your last numbers carry over automatically.")
            featureRow(icon: "arrow.up.forward.square.fill", tint: Theme.gold,
                       title: "Beat Last Time",
                       detail: "A built-in engine tells you exactly how much to add next session.")
            featureRow(icon: "photo.on.rectangle.angled", tint: Theme.cyan,
                       title: "Progress Photos",
                       detail: "Same-pose timeline with drag-to-compare. Watch yourself change.")

            Spacer()

            VStack(spacing: 12) {
                Button {
                    ExerciseDBSeeder.seedPlans(context: context)
                    finish()
                } label: {
                    VStack(spacing: 2) {
                        Text("Guide Me — Use a Classic Plan")
                            .font(.headline)
                        Text("A/B full-body or Push/Pull/Legs, added to Plans")
                            .font(.caption2)
                            .opacity(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    finish()
                } label: {
                    VStack(spacing: 2) {
                        Text("I Have My Own Plan")
                            .font(.headline)
                        Text("Log freestyle — 800+ exercises included")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func featureRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    private func finish() {
        WeeklyRecapScheduler.shared.scheduleIfNeeded(context: context)
        withAnimation { onboardingDone = true }
    }
}
