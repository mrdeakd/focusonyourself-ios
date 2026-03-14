import SwiftUI

struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel
    @State private var showChangeNameSheet = false
    @State private var showChangeCategoriesSheet = false

    init() {
        _viewModel = State(initialValue: SettingsViewModel())
    }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header
                HStack {
                    Text("Settings")
                        .font(.foyNavTitle)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        nameSection
                        categoriesSection
                        notificationsSection
                        if viewModel.isAppleIntelligenceAvailable {
                            appleIntelligenceSection
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .sheet(isPresented: $showChangeNameSheet) {
            ChangeNameSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showChangeCategoriesSheet) {
            ChangeCategoriesSheet(viewModel: viewModel)
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("YOUR NAME")
            VStack(spacing: 0) {
                HStack {
                    Text(viewModel.currentName.isEmpty ? "Your name" : viewModel.currentName)
                        .font(.foyBody)
                        .foregroundStyle(viewModel.currentName.isEmpty ? Color.foyPlaceholder : Color.foyForeground)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

                Rectangle()
                    .fill(Color.foyBorder)
                    .frame(height: 1)

                Button {
                    showChangeNameSheet = true
                } label: {
                    HStack {
                        Text("Change name")
                            .font(.foyCaptionMedium)
                            .foregroundStyle(Color.foyNavy)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("AFFIRMATION CATEGORIES")
            VStack(spacing: 0) {
                HStack {
                    Text(viewModel.currentCategories.map(\.displayName).sorted().joined(separator: ", "))
                        .font(.foyHint)
                        .foregroundStyle(Color.foyForegroundSecondary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

                Rectangle()
                    .fill(Color.foyBorder)
                    .frame(height: 1)

                Button {
                    showChangeCategoriesSheet = true
                } label: {
                    HStack {
                        Text("Change categories")
                            .font(.foyCaptionMedium)
                            .foregroundStyle(Color.foyNavy)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("NOTIFICATIONS")
            HStack {
                Text("Daily 9am Reminder")
                    .font(.foyBody)
                    .foregroundStyle(Color.foyForeground)
                Spacer()
                FOYToggle(isOn: $viewModel.currentNotifications)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private var appleIntelligenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("APPLE INTELLIGENCE")
            VStack(spacing: 0) {
                HStack {
                    Text("Apple Intelligence")
                        .font(.foyBody)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                    FOYToggle(isOn: $viewModel.currentAppleIntelligence)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

                Divider()
                    .background(Color.foyBorder)
                    .padding(.horizontal, Spacing.md)

                Text("After check-in, generate a personalized affirmation using on-device AI. Requires iPhone 15 Pro or newer.")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyPlaceholder)
                    .lineSpacing(Spacing.xxs)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .foySectionLabelStyle()
            .foregroundStyle(Color.foyPlaceholder)
    }
}
