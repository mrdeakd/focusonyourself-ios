import StoreKit
import SwiftUI

struct PaywallScreen: View {
    @State private var viewModel = PaywallViewModel()

    private let benefits: [(symbol: String, title: String, subtitle: String)] = [
        ("lock.open", "All Categories", "Confidence, Health, Relationships & more"),
        ("sparkles", "AI Affirmations", "Personalized with Apple Intelligence"),
        ("timer", "Custom Reminder Time", "Set your perfect daily moment"),
        ("gift", "Future Features", "Get everything we build next")
    ]

    private let loadingOverlay = Color.foyScrim

    // Screen has no header: sheet paywall uses drag handle + custom title layout
    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    SheetDragHandle()

                    VStack(spacing: 0) {
                        PaywallDismissButton()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, Spacing.xs)

                        PaywallTitleSection()
                            .padding(.top, Spacing.sm)

                        PaywallBenefitsList(benefits: benefits)
                            .padding(.top, Spacing.xl)

                        PaywallPlanToggle(viewModel: viewModel)
                            .padding(.top, Spacing.xl)

                        PaywallCtaSection(viewModel: viewModel)
                            .padding(.top, Spacing.lg)
                            .padding(.bottom, Spacing.screenBottom)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }
            }
            .scrollIndicators(.hidden)

            if viewModel.isLoading {
                loadingOverlay.ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }

            if viewModel.showSuccess {
                PaywallSuccessView(onContinue: { viewModel.dismissSuccess() })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showSuccess)
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: viewModel.isPro) { _, isPro in
            if isPro && !viewModel.showSuccess { dismiss() }
        }
        .onChange(of: viewModel.shouldDismiss) { _, should in
            if should { dismiss() }
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
    }

    @Environment(\.dismiss) private var dismiss
}
