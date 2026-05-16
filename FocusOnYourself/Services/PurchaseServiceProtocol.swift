import Foundation
import StoreKit

enum PurchaseOutcome {
    case success
    case pending   // awaiting parental/SCA approval
    case cancelled
}

protocol PurchaseServiceProtocol: AnyObject {
    var isPro: Bool { get }
    var products: [Product] { get }
    var productMonthly: String { get }
    var productAnnual: String { get }

    func purchase(_ product: Product) async throws -> PurchaseOutcome
    func restorePurchases() async throws
    func refreshEntitlements() async
}
