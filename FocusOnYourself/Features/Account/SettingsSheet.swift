import SwiftUI

struct SettingsSheet: View {
    var viewModel: AccountViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                SheetDragHandle()
                SheetHeader(title: "Settings") { dismiss() }

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
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
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
        .sheet(isPresented: Bindable(viewModel).showChangeNameSheet) {
            ChangeNameSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showChangeCategoriesSheet) {
            ChangeCategoriesSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showDailyContextSheet) {
            DailyContextSheet(viewModel: viewModel)
        }
        // swiftlint:disable vertical_parameter_alignment_on_call
        .confirmationDialog(
            "Reset All Progress?",
            isPresented: Bindable(viewModel).showResetConfirmation,
            titleVisibility: .visible
        ) { // swiftlint:enable vertical_parameter_alignment_on_call
            Button("Reset Everything", role: .destructive) {
                Task { await viewModel.resetAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your check-ins, streaks, and settings. This cannot be undone.")
        }
    }
}
