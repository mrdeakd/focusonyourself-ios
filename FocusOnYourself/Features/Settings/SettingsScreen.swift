import SwiftUI

struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel

    private let inputFieldHeight: CGFloat = 52
    private let iconSize: CGFloat = 18
    private let saveFontMedium15 = Font.custom("Inter", size: 15).weight(.medium)

    init(appState: AppState) {
        _viewModel = State(initialValue: SettingsViewModel(appState: appState))
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
                    Button("Save") {
                        viewModel.save()
                    }
                    .font(saveFontMedium15)
                    .foregroundStyle(Color.foyNavy)
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
                        appleIntelligenceSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("YOUR NAME")
            TextField("Your name", text: $viewModel.draftName)
                .font(.foyBody)
                .foregroundStyle(Color.foyForeground)
                .padding(.horizontal, Spacing.md)
                .frame(height: inputFieldHeight)
                .background(Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.foyBorder, lineWidth: 1)
                )
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("AFFIRMATION CATEGORIES")
            VStack(spacing: 0) {
                ForEach(Array(AffirmationCategory.allCases.enumerated()), id: \.element.id) { index, category in
                    VStack(spacing: 0) {
                        if index > 0 {
                            Divider()
                                .background(Color.foyBorder)
                        }
                        HStack {
                            Text(category.displayName)
                                .font(.foyBody)
                                .foregroundStyle(Color.foyForeground)
                            Spacer()
                            let isSelected = viewModel.draftCategories.contains(category)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .resizable()
                                .frame(width: iconSize, height: iconSize)
                                .foregroundStyle(isSelected ? Color.foyNavy : Color.foyButtonDisabled)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.md)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.draftCategories.contains(category) {
                                viewModel.draftCategories.remove(category)
                            } else {
                                viewModel.draftCategories.insert(category)
                            }
                        }
                    }
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
                FOYToggle(isOn: $viewModel.draftNotifications)
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
                    FOYToggle(isOn: $viewModel.draftAppleIntelligence)
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
