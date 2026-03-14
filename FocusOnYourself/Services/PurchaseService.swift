import Foundation
import StoreKit

enum PurchaseError: Error {
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

@Observable
@MainActor
final class PurchaseService: PurchaseServiceProtocol {

    private let productMonthly = "com.focusonyourself.pro.monthly"
    private let productAnnual = "com.focusonyourself.pro.annual"
    private let isProUserDefaultsKey = "com.focusonyourself.isPro"

    var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: isProUserDefaultsKey) }
    }
    var products: [Product] = []

    nonisolated(unsafe) private var updatesTask: Task<Void, Never>?

    init() {
        isPro = UserDefaults.standard.bool(forKey: "com.focusonyourself.isPro")
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
        updatesTask = Task {
            for await _ in Transaction.updates {
                await refreshEntitlements()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func purchase(_ product: Product) async throws {
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch StoreKitError.userCancelled {
            throw PurchaseError.userCancelled
        } catch {
            throw PurchaseError.purchaseFailed
        }

        switch result {
        case .success(let verification):
            let transaction = try verifiedTransaction(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            throw PurchaseError.userCancelled
        case .pending:
            break
        @unknown default:
            throw PurchaseError.purchaseFailed
        }
    }

    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
        } catch {
            throw PurchaseError.purchaseFailed
        }
        await refreshEntitlements()
    }

    private func loadProducts() async {
        let productIDs: Set<String> = [productMonthly, productAnnual]
        products = (try? await Product.products(for: productIDs)) ?? []
    }

    private func refreshEntitlements() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               (transaction.productID == productMonthly || transaction.productID == productAnnual),
               transaction.revocationDate == nil {
                hasEntitlement = true
                break
            }
        }
        isPro = hasEntitlement
    }

    private func verifiedTransaction(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw PurchaseError.verificationFailed
        }
    }
}
