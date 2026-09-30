import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("onboardingDone") private var onboardingDone = false
    @AppStorage("healthkitEnabled") private var healthkitEnabled = false
    @StateObject private var purchaseManager = PurchaseManager.shared
    @ObservedObject private var quota = QuotaStore.shared
    @ObservedObject private var aiRouter = AIRouter.shared
    @State private var showPaywall = false
    @State private var csvURL: URL?
    @State private var exportError: String?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            List {
                proSection
                aiSection
                appleHealthSection
                dataSection
                legalSection
                supportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: Binding(
                get: { csvURL.map(ExportFile.init(url:)) },
                set: { _ in csvURL = nil }
            )) { file in
                ShareSheet(items: [file.url])
            }
            .alert("Export Failed", isPresented: .init(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private struct ExportFile: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                Label(purchaseManager.isLifetime ? "Lifetime · BYO Key active" : "Pro subscription active", systemImage: "crown.fill")
                    .foregroundStyle(Theme.gold)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.gold)
                }
            }
            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                Label("Manage Subscription", systemImage: "arrow.triangle.2.circlepath")
            }
        } header: {
            Text("Gainsday Pro")
        } footer: {
            Text("Annual includes a 7-day free trial. Cancel anytime — your logged history stays free forever.")
        }
    }

    private var aiSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Intelligence (on-device)")
                        .font(.subheadline.weight(.semibold))
                    Text(aiRouter.hasOnDeviceAI()
                         ? "Available — free, private, unlimited."
                         : "Requires iOS 26 or later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let byo = AIConfiguration.loadBYO() {
                HStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(Theme.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your API Key")
                            .font(.subheadline.weight(.semibold))
                        Text("\(byo.resolvedProfile?.displayName ?? byo.providerID) · \(byo.model)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            NavigationLink {
                AISettingsView()
            } label: {
                Label("AI Coach & API Keys", systemImage: "key.horizontal.fill")
            }
            HStack {
                Text("Cloud AI quota")
                Spacer()
                Text(quota.quotaLabel())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("AI Coach")
        } footer: {
            Text("The form coach uses Apple Intelligence first. Add your own API key for unlimited vision feedback, or use the included monthly cloud quota.")
        }
    }

    private var appleHealthSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
                Text("HealthKit Integration")
                    .font(.subheadline.weight(.semibold))
            }
            Toggle(isOn: Binding(
                get: { healthkitEnabled },
                set: { newValue in
                    healthkitEnabled = newValue
                    if newValue {
                        Task { await HealthKitService.shared.requestAuthorization() }
                    }
                }
            )) {
                Label("Sync Workouts to HealthKit", systemImage: "heart.text.square.fill")
            }
            .disabled(!HealthKitService.shared.isAvailable)
            NavigationLink {
                HealthKitInfoView()
            } label: {
                Label("Learn More", systemImage: "info.circle")
                    .foregroundStyle(Theme.orange)
            }
        } header: {
            Label("Apple Health (HealthKit)", systemImage: "heart.text.square.fill")
        } footer: {
            Text("When enabled, Gainsday writes each finished workout to Apple Health as a Traditional Strength Training workout (duration and total volume). Gainsday never reads health data. You can revoke access anytime in the iOS Health app.")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                exportCSV()
            } label: {
                Label("Export All Sets (CSV)", systemImage: "square.and.arrow.up")
            }
            HStack(spacing: 10) {
                Image(systemName: "icloud.fill")
                    .foregroundStyle(Theme.cyan)
                Text("iCloud Sync")
                Spacer()
                Text("Automatic")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Your log lives on this device first and syncs through your own iCloud (no account needed). Exports are plain CSV.")
        }
    }

    private var legalSection: some View {
        Section {
            Link(destination: URL(string: "https://asunnyboy861.github.io/Gainsday/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/Gainsday/terms.html")!) {
                Label("Terms of Use (EULA)", systemImage: "doc.plaintext")
            }
            NavigationLink {
                exerciseCreditsView
            } label: {
                Label("Exercise Data Credits", systemImage: "dumbbell.fill")
            }
        } header: {
            Text("Legal")
        }
    }

    private var exerciseCreditsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Exercise Library Data")
                    .font(.title2.weight(.bold))
                Text("The 876-exercise library in Gainsday is based on the open-source free-exercise-database by yuhonas (MIT License).")
                    .font(.subheadline)
                Link("github.com/yuhonas/free-exercise-db",
                     destination: URL(string: "https://github.com/yuhonas/free-exercise-db")!)
                    .font(.subheadline)
                    .foregroundStyle(Theme.orange)
                Text("Exercise descriptions are provided for informational purposes only and are not a substitute for professional coaching or medical advice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Exercise Data Credits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var supportSection: some View {
        Section {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
            }
        } header: {
            Text("Support")
        } footer: {
            Text("Bug reports, billing questions, and feature ideas all reach a real human.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            Button("View Onboarding Again") {
                onboardingDone = false
            }
        } footer: {
            Text("Gainsday \(appVersion) · Copyright © 2026 he zhou")
        }
    }

    private func exportCSV() {
        let descriptor = FetchDescriptor<SetEntry>(sortBy: [SortDescriptor(\.createdAt)])
        let entries = (try? context.fetch(descriptor)) ?? []
        guard !entries.isEmpty else {
            exportError = "No sets logged yet — nothing to export."
            return
        }
        let csv = CSVExporter.export(entries: entries)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(CSVExporter.fileName())
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            csvURL = url
        } catch {
            exportError = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
