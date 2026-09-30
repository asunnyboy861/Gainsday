import SwiftUI

struct HealthKitInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity)

                Text("Apple Health (HealthKit) Integration")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                infoRow(icon: "arrow.up.heart.fill", tint: .pink,
                        title: "What Gainsday writes",
                        detail: "Each finished workout is saved to Apple Health as a Traditional Strength Training workout, including its duration and total volume.")

                infoRow(icon: "lock.shield.fill", tint: .blue,
                        title: "Your data stays yours",
                        detail: "Gainsday only writes workout records. It never reads health data, and nothing leaves your device except through your own iCloud sync.")

                infoRow(icon: "gearshape.fill", tint: .gray,
                        title: "How to turn it off",
                        detail: "Toggle “Sync Workouts to HealthKit” off in Settings > Apple Health, or manage permissions in the iOS Health app under Sources.")

                infoRow(icon: "questionmark.circle.fill", tint: Theme.orange,
                        title: "Why we use it",
                        detail: "HealthKit lets your training live alongside the rest of your health data — rings, steps, and workouts in one place.")
            }
            .padding()
        }
        .background(Theme.charcoal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func infoRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
