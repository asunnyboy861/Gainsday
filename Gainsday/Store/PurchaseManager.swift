import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let yearlyID = "gainsday.pro.yearly"
    static let monthlyID = "gainsday.pro.monthly"
    static let lifetimeID = "gainsday.lifetime.byo"

    @Published var isPro: Bool = false
    @Published var isLifetime: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await checkPurchased() }
    }

    var proProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [Self.yearlyID, Self.monthlyID, Self.lifetimeID])
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkPurchased()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchased()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func checkPurchased() async {
        var pro = false
        var lifetime = false
        let yearly = try? await Transaction.currentEntitlement(for: Self.yearlyID)
        let monthly = try? await Transaction.currentEntitlement(for: Self.monthlyID)
        let lifetimeEntitlement = try? await Transaction.currentEntitlement(for: Self.lifetimeID)
        pro = yearly != nil || monthly != nil
        lifetime = lifetimeEntitlement != nil
        isPro = pro
        isLifetime = lifetime
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkPurchased()
                    }
                }
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }
}
