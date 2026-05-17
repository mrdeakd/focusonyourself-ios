import Factory
import Foundation
import StoreKit

final class PurchaseService: PurchaseServiceProtocol {
    let productMonthly = "com.focusonyourself.pro.monthly.renewal"
    let productAnnual  = "com.focusonyourself.pro.annual.renewal"

    @Injected(\.userDefaultsService) private var userDefaultsService

    private var _isPro = false

    var isPro: Bool {
        #if DEBUG
        if userDefaultsService.getBool(.isProDebugOverride) {
            return true
        }
        #endif
        return _isPro
    }

    private var updatesTask: Task<Void, Never>?
    private var isProContinuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    init() {
        _isPro = _userDefaultsService.wrappedValue.getBool(.isPro)
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
        _isPro = hasEntitlement
        userDefaultsService.setBool(.isPro, value: hasEntitlement)
        notifyAll()
    }
}

// MARK: - State Stream

extension PurchaseService {
    func isProUpdates() -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            self?.isProContinuations[id] = continuation
            continuation.yield(self?.isPro ?? false)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isProContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    private func notifyAll() {
        isProContinuations.values.forEach { $0.yield(isPro) }
    }
}
