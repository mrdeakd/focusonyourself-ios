import Foundation

struct SubscriptionVerifyResponse: Decodable {
    let isPro: Bool
    let expiresAt: String?
    let productId: String?
}
