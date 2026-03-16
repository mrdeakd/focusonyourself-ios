import SwiftUI
import StoreKit

struct PaywallScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaywallViewModel()

    private let benefits: [(symbol: String, title: String, subtitle: String)] = [
        ("lock.open",  "All Categories",         "Confidence, Health, Relationships & more"),
        ("sparkles",   "AI Affirmations",         "Personalized with Apple Intelligence"),
        ("timer",      "Custom Reminder Time",    "Set your perfect daily moment"),
        ("gift",       "Future Features",         "Get everything we build next"),
    ]

    private let defaultMonthlyPrice = "$2.99/mo"
    private let defaultAnnualPrice  = "$19.99/yr"
    private let planToggleHeight: CGFloat = 56
    private let bestValueBadgeCornerRadius: CGFloat = 10
    private let loadingOverlay = Color.black.opacity(0.4)
    private let dismissButtonBackground = Color.foyMoodBackground
    private let dismissButtonSize: CGFloat = 32
    private let handleBarWidth: CGFloat = 36
    private let handleBarHeight: CGFloat = 4

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    handleBar
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.sm)

                    dismissButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.xs)

                    titleSection
                        .padding(.top, Spacing.sm)
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
                loadingOverlay.ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
        .onChange(of: viewModel.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    private var handleBar: some View {
        RoundedRectangle(cornerRadius: handleBarHeight / 2)
            .fill(Color.foyButtonDisabled)
            .frame(width: handleBarWidth, height: handleBarHeight)
            .frame(maxWidth: .infinity)
    }

    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(dismissButtonBackground)
                    .frame(width: dismissButtonSize, height: dismissButtonSize)
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: Spacing.xxs) {
            Text("Unlock FocusOnYourself Pro")
                .font(.foyHeadline)
                .kerning(-0.3)
                .foregroundStyle(Color.foyForeground)
                .multilineTextAlignment(.center)

            Text("Everything you need for daily growth")
                .font(.foyCaption)
                .foregroundStyle(Color.foyForegroundSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var benefitsList: some View {
        VStack(spacing: Spacing.xxxs) {
            ForEach(benefits, id: \.symbol) { benefit in
                BenefitRow(symbol: benefit.symbol, title: benefit.title, subtitle: benefit.subtitle)
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
                        .foregroundStyle(isSelected ? .white : Color.foyForeground)

                    Text(price)
                        .font(.foyCaption)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.foyForegroundSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: planToggleHeight)
                .background(isSelected ? Color.foyNavy : Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .strokeBorder(isSelected ? Color.clear : Color.foyNavy, lineWidth: 1.5)
                )

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
                Text(viewModel.ctaLabel)
                    .font(.foyButtonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.inputHeight)
                    .background(Color.foyNavy)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
            }
            .disabled(viewModel.isLoading)

            Button {
                viewModel.restore()
            } label: {
                Text("Restore Purchase")
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyPlaceholder)
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
