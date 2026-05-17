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

    // Pencil design node: JTVCT
    private var settingsFAB: some View {
        Button {
            viewModel.showSettingsSheet = true
        } label: {
            VStack(spacing: Spacing.xxs) {
                ZStack {
                    Circle()
                        .fill(Color.foyNavy)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.foyNavy.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.foyOnPrimary)
                        .accessibilityHidden(true)
                }
                Text("Settings")
                    .font(.foyMicroMedium)
                    .foregroundStyle(Color.foyNavy)
            }
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
