import Factory
import Foundation
import StoreKit

final class PurchaseUseCase: PurchaseUseCaseProtocol {
    @Injected(\.purchaseService) private var purchaseService

    var isPro: Bool { purchaseService.isPro }

    func loadProducts() async -> [Product] {
        await purchaseService.loadProducts()
    }

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        try await purchaseService.purchase(product)
    }

    func restorePurchases() async throws {
        try await purchaseService.restorePurchases()
    }

    func refreshEntitlements() async {
        await purchaseService.refreshEntitlements()
    }
}
