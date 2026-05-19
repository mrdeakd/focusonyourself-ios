import Foundation
import Observation
import StoreKit

@Observable
final class PurchaseUseCase: PurchaseUseCaseProtocol {
    private(set) var isPro = false

    @ObservationIgnored private let defaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        isPro = defaults.bool(forKey: UserDefaultsKey.isPro.rawValue)
        Task { await refreshEntitlements() }
        updatesTask = Task {
            for await _ in Transaction.updates {
                await refreshEntitlements()
            }
        }
    }

    func loadProducts() async -> [Product] {
        do {
            return try await Product.products(for: [ProductID.monthly, ProductID.annual])
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
                transaction.productID == ProductID.monthly || transaction.productID == ProductID.annual,
                transaction.revocationDate == nil {
                hasEntitlement = true
                break
            }
        }
        isPro = hasEntitlement
        defaults.set(hasEntitlement, forKey: UserDefaultsKey.isPro.rawValue)
    }
}
