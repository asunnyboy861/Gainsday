import Foundation
import SwiftUI

@MainActor
final class QuotaStore: ObservableObject {
    static let shared = QuotaStore()

    @Published private(set) var usedThisMonth: Int {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard
    private static let limitFree = 3
    private static let limitPro = 60

    init() {
        let stored = defaults.string(forKey: "quota.month")
        let key = Self.monthKey()
        let used = defaults.integer(forKey: "quota.used")
        usedThisMonth = (stored == key) ? used : 0
    }

    static func monthKey(_ date: Date = .now) -> String {
        DayKey.key(for: date).prefix(7).description
    }

    var monthlyLimit: Int {
        if AIConfiguration.hasAPIKey { return .max }
        let pm = PurchaseManager.shared
        if pm.isLifetime { return 0 }
        if pm.isPro { return Self.limitPro }
        return Self.limitFree
    }

    var remaining: Int {
        monthlyLimit == .max ? .max : max(0, monthlyLimit - usedThisMonth)
    }

    var canUseEmbedded: Bool {
        guard EmbeddedAIBackend.isConfigured else { return false }
        guard remaining > 0 else { return false }
        return true
    }

    func consume() {
        usedThisMonth += 1
    }

    func resetIfNewMonth() {
        let key = Self.monthKey()
        if defaults.string(forKey: "quota.month") != key {
            usedThisMonth = 0
            defaults.set(key, forKey: "quota.month")
        }
    }

    private func save() {
        defaults.set(Self.monthKey(), forKey: "quota.month")
        defaults.set(usedThisMonth, forKey: "quota.used")
    }

    func quotaLabel() -> String {
        let limit = monthlyLimit
        if limit == .max { return "Unlimited (your own key)" }
        if limit == 0 { return "Bring your own key to unlock" }
        return "\(usedThisMonth)/\(limit) this month"
    }
}
