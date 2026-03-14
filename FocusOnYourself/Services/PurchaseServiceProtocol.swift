import Foundation
import StoreKit

protocol PurchaseServiceProtocol: AnyObject {
    var isPro: Bool { get }
    var products: [Product] { get }
    func purchase(_ product: Product) async throws
    func restorePurchases() async throws
}
