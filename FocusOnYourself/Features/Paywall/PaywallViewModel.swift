import Factory
import Foundation
import Observation
import StoreKit

@Observable @MainActor
final class PaywallViewModel {
    @ObservationIgnored @Injected(\.purchaseUseCase) private var purchaseUseCase

    // MARK: - State

    var selectedPlan: Plan = .annual
    var isLoading = false
    var error: ErrorInfo?
    var shouldDismiss = false
    var showSuccess = false
    var products: [Product]

    // MARK: - Computed

    var isPro: Bool { purchaseUseCase.isPro }

    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthly }
    }

    var annualProduct: Product? {
        products.first { $0.id == ProductID.annual }
    }

    var selectedProduct: Product? {
        selectedPlan == .monthly ? monthlyProduct : annualProduct
    }

    var ctaDisabled: Bool {
        isLoading || selectedProduct == nil
    }

    var ctaLabel: String {
        guard let offer = selectedProduct?.subscription?.introductoryOffer,
            offer.paymentMode == .freeTrial else {
            return "Subscribe Now"
        }
        let period = offer.period
        if period.unit == .day {
            return "Start \(period.value)-Day Free Trial"
        }
        return "Start Free Trial"
    }

    init() {
        products = []
    }

    // MARK: - Public methods

    func onAppear() async {
        async let loadedProducts = purchaseUseCase.loadProducts()
        await purchaseUseCase.refreshEntitlements()
        products = await loadedProducts
    }

    func purchase() {
        error = nil

        guard let product = selectedProduct else {
            error = ErrorInfo(
                title: "Products Unavailable",
                description: "Please try again in a moment."
            )
            return
        }

        isLoading = true

        Task {
            do {
                let outcome = try await purchaseUseCase.purchase(product)
                switch outcome {
                case .success:
                    showSuccess = true
                case .pending:
                    error = ErrorInfo(
                        title: "Purchase Pending",
                        description: "Awaiting approval. You'll get access once it's approved."
                    )
                case .cancelled:
                    break
                }
            } catch let purchaseError as PurchaseError {
                error = ErrorInfo(purchaseError)
            } catch {
                self.error = ErrorInfo(title: "Purchase failed", description: "Something went wrong. Please try again.")
            }
            isLoading = false
        }
    }

    func dismissSuccess() {
        shouldDismiss = true
    }

    func restore() {
        error = nil
        isLoading = true

        Task {
            do {
                try await purchaseUseCase.restorePurchases()
            } catch let purchaseError as PurchaseError {
                if purchaseError != .userCancelled {
                    error = ErrorInfo(purchaseError)
                }
            } catch {
                self.error = ErrorInfo(title: "Restore failed", description: "Something went wrong. Please try again.")
            }
            isLoading = false
        }
    }

    enum Plan { case monthly, annual }
}
