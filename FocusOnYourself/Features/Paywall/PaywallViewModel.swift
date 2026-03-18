import Factory
import Foundation
import Observation
import StoreKit

@Observable
@MainActor
final class PaywallViewModel {
    enum Plan { case monthly, annual }

    var selectedPlan: Plan = .annual
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService

    var monthlyProduct: Product? {
        purchaseService.products.first { $0.id == purchaseService.productMonthly }
    }

    var annualProduct: Product? {
        purchaseService.products.first { $0.id == purchaseService.productAnnual }
    }

    var selectedProduct: Product? {
        selectedPlan == .monthly ? monthlyProduct : annualProduct
    }

    var isPro: Bool {
        purchaseService.isPro
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

    func purchase() {
        guard let product = selectedProduct else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await purchaseService.purchase(product)
            } catch let error as PurchaseError {
                if error != .userCancelled {
                    errorMessage = error.defaultDescription
                }
            } catch {}
            isLoading = false
        }
    }

    func restore() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await purchaseService.restorePurchases()
            } catch let error as PurchaseError {
                if error != .userCancelled {
                    errorMessage = error.defaultDescription
                }
            } catch {}
            isLoading = false
        }
    }
}
