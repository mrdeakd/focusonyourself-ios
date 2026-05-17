import Factory
import Foundation
import StoreKit

enum PurchaseError: Error, Equatable {
    case purchaseFailed
    case verificationFailed
    case userCancelled

    var defaultDescription: String {
        switch self {
        case .purchaseFailed:      return "The purchase could not be completed."
        case .verificationFailed:  return "Transaction verification failed."
        case .userCancelled:       return "The purchase was cancelled."
        }
    }
}

final class PurchaseService: PurchaseServiceProtocol {
    let productMonthly = "com.focusonyourself.pro.monthly.renewal"
    let productAnnual  = "com.focusonyourself.pro.annual.renewal"

    @Injected(\.userDefaultsService) private var userDefaultsService

    var isPro: Bool { userDefaultsService.getBool(.isPro) }

    private var updatesTask: Task<Void, Never>?

    init() {
        Task { await refreshEntitlements() }
        updatesTask = Task {
            for await _ in Transaction.updates {
                await refreshEntitlements()
            }
        }
    }

    func loadProducts() async -> [Product] {
        do {
            return try await Product.products(for: [productMonthly, productAnnual])
        } catch {
            return []
        }
    }

    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch StoreKitError.userCancelled {
            return .cancelled
        } catch {
            throw PurchaseError.purchaseFailed
        }

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw PurchaseError.verificationFailed
            }
            await transaction.finish()
            await refreshEntitlements()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            throw PurchaseError.purchaseFailed
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
                transaction.productID == productMonthly || transaction.productID == productAnnual,
                transaction.revocationDate == nil {
                hasEntitlement = true
                break
            }
        }
        userDefaultsService.setBool(.isPro, value: hasEntitlement)
    }
}
