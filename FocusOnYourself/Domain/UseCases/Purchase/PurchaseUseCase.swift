import Factory
import Foundation
import Observation
import StoreKit

@Observable
final class PurchaseUseCase: PurchaseUseCaseProtocol {
    private(set) var isPro = false

    @ObservationIgnored @Injected(\.userDefaultsStore) private var userDefaultsStore
    @ObservationIgnored @Injected(\.subscriptionService) private var subscriptionService
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        isPro = _userDefaultsStore.wrappedValue.bool(for: .isPro, defaultingTo: false)
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
            // Use the just-verified JWS directly. Transaction.currentEntitlements is
            // eventually-consistent after transaction.finish(); waiting for it would
            // leave isPro=false until Transaction.updates ticks asynchronously.
            do {
                let response = try await subscriptionService.verify(
                    signedTransaction: verification.jwsRepresentation
                )
                isPro = response.isPro
                userDefaultsStore.setBool(response.isPro, for: .isPro)
            } catch {
                // Backend unreachable — Transaction.updates listener will retry via refreshEntitlements
            }
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
        var serverIsPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified = result else { continue }
            do {
                let response = try await subscriptionService.verify(signedTransaction: result.jwsRepresentation)
                if response.isPro { serverIsPro = true }
            } catch {
                // Network failure mid-loop — preserve the previously cached isPro value
                return
            }
        }
        isPro = serverIsPro
        userDefaultsStore.setBool(serverIsPro, for: .isPro)
    }
}
