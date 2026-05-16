import StoreKit
import SwiftUI

struct PaywallPlanToggle: View {
    var viewModel: PaywallViewModel

    private let defaultMonthlyPrice = "$1.99/mo"
    private let defaultAnnualPrice  = "$14.99/yr"

    var body: some View {
        HStack(spacing: Spacing.xs) {
            planButton(
                plan: .monthly,
                price: viewModel.monthlyProduct?.displayPrice ?? defaultMonthlyPrice,
                showBadge: false
            )
            planButton(
                plan: .annual,
                price: viewModel.annualProduct?.displayPrice ?? defaultAnnualPrice,
                showBadge: true
            )
        }
    }

    private func planButton(plan: PaywallViewModel.Plan, price: String, showBadge: Bool) -> some View {
        let isSelected = viewModel.selectedPlan == plan

        return Button {
            viewModel.selectedPlan = plan
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: Spacing.xxs) {
                    Text(plan == .monthly ? "Monthly" : "Annual")
                        .font(.foyBodyMedium)
                        .foregroundStyle(isSelected ? Color.foyOnPrimary : Color.foyForeground)

                    Text(price)
                        .font(.foyCaption)
                        .foregroundStyle(isSelected ? Color.foyOnPrimary.opacity(0.7) : Color.foyForegroundSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.inputHeight)
                .background(isSelected ? Color.foyNavy : Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .strokeBorder(isSelected ? Color.clear : Color.foyNavy, lineWidth: 1.5)
                }

                if showBadge {
                    Text("Best Value")
                        .font(.foyMicroMedium)
                        .foregroundStyle(Color.foyOnPrimary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxxs)
                        .background(Color.foyOrange)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.categoryTag))
                        .offset(x: -Spacing.xs, y: -Spacing.xs)
                }
            }
        }
    }
}
