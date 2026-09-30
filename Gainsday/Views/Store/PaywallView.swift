import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var selectedID: String = PurchaseManager.yearlyID
    @State private var purchasing = false
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if purchaseManager.isPro {
                        subscribedCard
                    } else {
                        ForEach(optionCards) { card in
                            optionRow(card)
                        }
                        subscribeButton
                        legalSection
                        restoreButton
                    }
                }
                .padding()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.charcoal)
            .navigationTitle("Gainsday Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await purchaseManager.loadProducts() }
            .onChange(of: purchaseManager.isPro) { _, isPro in
                if isPro { successMessage = "Pro unlocked. Welcome to unlimited gains tracking." }
            }
            .alert("Purchase Issue", isPresented: .init(
                get: { purchaseManager.loadError != nil },
                set: { if !$0 { purchaseManager.loadError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseManager.loadError ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.gold)
            Text("Beat last time, every time")
                .font(Theme.rounded(24))
            Text("The free tier logs forever. Pro adds advanced stats, AI form coach quota, and full history power tools.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private struct OptionCard: Identifiable {
        let id: String
        let title: String
        let price: String
        let badge: String?
        let detail: String
    }

    private var optionCards: [OptionCard] {
        [
            OptionCard(id: PurchaseManager.yearlyID,
                       title: "Annual",
                       price: purchaseManager.proProduct?.displayPrice ?? "$19.99 / year",
                       badge: "7-day free trial · Best value",
                       detail: "Full Pro for a year, auto-renews. Cancel anytime in Settings."),
            OptionCard(id: PurchaseManager.monthlyID,
                       title: "Monthly",
                       price: purchaseManager.monthlyProduct?.displayPrice ?? "$3.99 / month",
                       badge: nil,
                       detail: "Flexible month-to-month. Cancel anytime."),
            OptionCard(id: PurchaseManager.lifetimeID,
                       title: "Lifetime · Bring Your Own Key",
                       price: purchaseManager.lifetimeProduct?.displayPrice ?? "$49.99 once",
                       badge: "Pay once, own forever",
                       detail: "All Pro features forever. AI Coach runs on your own API key (Settings > AI Coach) — unlimited and 100% on your account.")
        ]
    }

    private func optionRow(_ card: OptionCard) -> some View {
        Button {
            selectedID = card.id
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selectedID == card.id ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selectedID == card.id ? Theme.orange : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(card.title).font(.headline).foregroundStyle(.primary)
                        if let badge = card.badge {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.gold.opacity(0.2)))
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    Text(card.price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(card.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selectedID == card.id ? Theme.orange : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var subscribeButton: some View {
        Button {
            purchase()
        } label: {
            HStack {
                Spacer()
                if purchasing || purchaseManager.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(selectedID == PurchaseManager.lifetimeID ? "Buy Lifetime" : "Start Pro")
                        .font(.headline)
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(purchasing || purchaseManager.isLoading)
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/Gainsday/privacy.html")!)
                Link("Terms of Use (EULA)", destination: URL(string: "https://asunnyboy861.github.io/Gainsday/terms.html")!)
            }
            .font(.caption.weight(.semibold))
            Text("Payment is charged to your Apple ID at confirmation. Annual plans include a 7-day free trial, then auto-renew unless canceled at least 24 hours before the period ends. Manage or cancel anytime in App Store Settings. Lifetime is a one-time, non-consumable purchase.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await purchaseManager.restorePurchases() }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var subscribedCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("You're all set!")
                .font(.title3.weight(.bold))
            Text(successMessage ?? "Your Pro benefits are active on this Apple ID.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func purchase() {
        guard let product = purchaseManager.products.first(where: { $0.id == selectedID }) else {
            purchaseManager.loadError = "Store options are still loading. Try again in a moment."
            return
        }
        purchasing = true
        Task {
            let ok = await purchaseManager.purchase(product)
            purchasing = false
            if ok {
                successMessage = "Purchase complete. Enjoy!"
            } else if let error = purchaseManager.loadError {
                successMessage = nil
                purchaseManager.loadError = error
            }
        }
    }
}
