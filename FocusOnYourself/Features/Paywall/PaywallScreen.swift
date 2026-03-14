import SwiftUI

struct PaywallScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaywallViewModel()

    private let benefits: [(symbol: String, label: String)] = [
        ("sparkles",           "All Categories"),
        ("brain.head.profile", "AI Affirmations"),
        ("clock",              "Custom Reminder Time"),
        ("gift",               "Future Features")
    ]

    private let defaultMonthlyPrice = "$2.99/mo"
    private let defaultAnnualPrice  = "$19.99/yr"
    private let planToggleHeight: CGFloat = 56
    private let bestValueBadgeCornerRadius: CGFloat = 10

    var body: some View {
        ZStack {
            Color.foyNavy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    dismissButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.screenTop)

                    titleSection
                        .padding(.top, Spacing.lg)
                        .padding(.horizontal, Spacing.screenHorizontal)

                    benefitsList
                        .padding(.top, Spacing.xl)
                        .padding(.horizontal, Spacing.screenHorizontal)

                    planToggle
                        .padding(.top, Spacing.xl)
                        .padding(.horizontal, Spacing.screenHorizontal)

                    ctaSection
                        .padding(.top, Spacing.lg)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.screenBottom)
                }
            }

            if viewModel.isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
    }

    // MARK: - Subviews

    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(Spacing.xs)
        }
    }

    private var titleSection: some View {
        Text("Unlock FocusOnYourself Pro")
            .foySectionTitleStyle()
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var benefitsList: some View {
        VStack(spacing: Spacing.md) {
            ForEach(benefits, id: \.symbol) { benefit in
                BenefitRow(symbol: benefit.symbol, label: benefit.label)
            }
        }
    }

    private var planToggle: some View {
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
                        .foregroundStyle(isSelected ? Color.foyNavy : .white)

                    Text(price)
                        .font(.foyCaption)
                        .foregroundStyle(isSelected ? Color.foyNavy.opacity(0.7) : .white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: planToggleHeight)
                .background(isSelected ? .white : .white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                if showBadge {
                    Text("Best Value")
                        .font(.foyMicroMedium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxxs)
                        .background(Color.foyOrange)
                        .clipShape(RoundedRectangle(cornerRadius: bestValueBadgeCornerRadius))
                        .offset(x: -Spacing.xs, y: -Spacing.xs)
                }
            }
        }
    }

    private var ctaSection: some View {
        VStack(spacing: Spacing.md) {
            Button {
                viewModel.purchase()
            } label: {
                Text("Start 7-Day Free Trial")
                    .font(.foyButtonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.inputHeight)
                    .background(Color.foyOrange)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
            }
            .disabled(viewModel.isLoading)

            Button {
                viewModel.restore()
            } label: {
                Text("Restore Purchase")
                    .font(.foyCaption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .disabled(viewModel.isLoading)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.foyHint)
                    .foregroundStyle(Color.foyOrange)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - BenefitRow

private struct BenefitRow: View {
    let symbol: String
    let label: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(Color.foyOrange)
                .frame(width: 24, alignment: .center)

            Text(label)
                .font(.foyBody)
                .foregroundStyle(.white)

            Spacer()
        }
    }
}
