import SwiftUI

struct SettingsScreen: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeaderView(title: "Account")

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        SettingsAccountSection(viewModel: viewModel)
                        if !viewModel.isPro {
                            SettingsSubscriptionSection(showPaywall: Bindable(viewModel).showPaywall)
                        }
                        SettingsNameSection(viewModel: viewModel)
                        SettingsCategoriesSection(viewModel: viewModel)
                        SettingsNotificationsSection(viewModel: viewModel)
                        SettingsDailyContextSection(viewModel: viewModel)
                        SettingsAppearanceSection(viewModel: viewModel)
                        SettingsResetSection(viewModel: viewModel)
                        if viewModel.isAppleIntelligenceAvailable && viewModel.isPro {
                            SettingsAppleIntelligenceSection(viewModel: viewModel)
                        }
                        if viewModel.isAuthenticated {
                            signOutSection
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(isPresented: Bindable(viewModel).showChangeNameSheet) {
            ChangeNameSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showChangeCategoriesSheet) {
            ChangeCategoriesSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showDailyContextSheet) {
            DailyContextSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showPaywall) {
            PaywallScreen()
        }
        // swiftlint:disable vertical_parameter_alignment_on_call
        .confirmationDialog(
            "Reset All Progress?",
            isPresented: Bindable(viewModel).showResetConfirmation,
            titleVisibility: .visible
        ) { // swiftlint:enable vertical_parameter_alignment_on_call
            Button("Reset Everything", role: .destructive) {
                viewModel.resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your check-ins, streaks, and settings. This cannot be undone.")
        }
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
