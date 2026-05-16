import SwiftUI

struct SettingsScreen: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScreenHeaderView(title: "Settings") {
                    Text(viewModel.isPro ? "PRO" : "FREE")
                        .font(.foySectionLabelSemibold)
                        .foregroundStyle(viewModel.isPro ? Color.foyOrangeAccent : Color.foyNavy)
                        .padding(.horizontal, Spacing.badgeHorizontal)
                        .padding(.vertical, Spacing.xxxs)
                        .background(viewModel.isPro ? Color.foyOrangeAccent.opacity(0.15) : Color.foyFreeBadgeBg)
                        .clipShape(Capsule())
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
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
}
