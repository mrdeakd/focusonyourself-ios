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

private let kProductMonthlyID = "com.focusonyourself.pro.monthly.renewal"
private let kProductAnnualID  = "com.focusonyourself.pro.annual.renewal"

@Observable
@MainActor
final class PurchaseService: PurchaseServiceProtocol {
    let productMonthly = kProductMonthlyID
    let productAnnual  = kProductAnnualID

    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService

    var isPro: Bool {
        didSet { userDefaultsService.setBool(.isPro, value: isPro) }
    }
    var products: [Product] = []

    private var updatesTask: Task<Void, Never>?

    init() {
        isPro = false
        isPro = userDefaultsService.getBool(.isPro)
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
            let transaction = try verifiedTransaction(verification)
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
        do {
            try await AppStore.sync()
        } catch {
            throw PurchaseError.purchaseFailed
        }
        await refreshEntitlements()
    }

    private func loadProducts() async {
        let productIDs: Set<String> = [productMonthly, productAnnual]
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            products = []
        }
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
