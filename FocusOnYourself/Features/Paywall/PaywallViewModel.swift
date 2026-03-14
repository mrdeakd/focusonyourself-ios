import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class PaywallViewModel {
    enum Plan { case monthly, annual }

    var selectedPlan: Plan = .annual
    var isLoading = false
    var errorMessage: String?

    private let monthlyProductID = "com.focusonyourself.pro.monthly"
    private let annualProductID  = "com.focusonyourself.pro.annual"
    private let purchaseService: PurchaseServiceProtocol

    init(purchaseService: PurchaseServiceProtocol = ServiceContainer.shared.purchaseService) {
        self.purchaseService = purchaseService
    }

    var monthlyProduct: Product? {
        purchaseService.products.first { $0.id == monthlyProductID }
    }

    var annualProduct: Product? {
        purchaseService.products.first { $0.id == annualProductID }
    }

    var selectedProduct: Product? {
        selectedPlan == .monthly ? monthlyProduct : annualProduct
    }

    var ctaLabel: String {
        guard let offer = selectedProduct?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else {
            return "Subscribe Now"
        }
        let p = offer.period
        if p.unit == .day {
            return "Start \(p.value)-Day Free Trial"
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
                errorMessage = error.defaultDescription
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
                errorMessage = error.defaultDescription
            } catch {}
            isLoading = false
        }
    }
}
