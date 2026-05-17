import SwiftUI

// Pencil design: AccountScreen node gkxdM · FAB node ogtK7
struct SettingsScreen: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeaderView(title: "Account")

                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            SettingsAccountSection(viewModel: viewModel)
                            if !viewModel.isPro {
                                SettingsSubscriptionSection(showPaywall: Bindable(viewModel).showPaywall)
                            }
                            if viewModel.isAuthenticated {
                                signOutSection
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.screenBottom)
                    }
                    .scrollIndicators(.hidden)

                    settingsFAB
                        .padding(.trailing, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.lg)
                }
            }
        }
        .sheet(isPresented: Bindable(viewModel).showPaywall) {
            PaywallScreen()
        }
        .sheet(isPresented: Bindable(viewModel).showSettingsSheet) {
            SettingsSheet(viewModel: viewModel)
        }
    }

    // MARK: - Subviews

    private var settingsFAB: some View {
        Button {
            viewModel.showSettingsSheet = true
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "gearshape.fill")
                    .font(.foyHintMedium)
                    .accessibilityHidden(true)
                Text("Settings")
                    .font(.foyBodyMedium)
            }
            .foregroundStyle(Color.foyOnPrimary)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(Color.foyNavy)
            .clipShape(Capsule())
            .shadow(color: Color.foyNavy.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Open Settings")
    }

    private var signOutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("ACCOUNT")
            Button {
                Task { await viewModel.signOut() }
            } label: {
                HStack {
                    Text("Sign Out")
                        .font(.foyBody)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}
