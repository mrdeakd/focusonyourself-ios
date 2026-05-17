import Foundation
import StoreKit

protocol PurchaseServiceProtocol {
    var isPro: Bool { get }

    func loadProducts() async -> [Product]
    func purchase(_ product: Product) async throws -> PurchaseOutcome
    func restorePurchases() async throws
    func refreshEntitlements() async
}
