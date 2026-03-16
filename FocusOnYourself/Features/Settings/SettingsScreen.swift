import SwiftUI

struct SettingsScreen: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showChangeNameSheet = false
    @State private var showChangeCategoriesSheet = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.foyNavTitle)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                    Text(viewModel.isPro ? "PRO" : "FREE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(viewModel.isPro ? Color.foyOrangeAccent : Color.foyNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(viewModel.isPro ? Color.foyOrangeAccent.opacity(0.15) : Color.foyFreeBadgeBg)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        if !viewModel.isPro {
                            subscriptionSection
                        }
                        nameSection
                        categoriesSection
                        notificationsSection
                        appearanceSection
                        if viewModel.isAppleIntelligenceAvailable && viewModel.isPro {
                            appleIntelligenceSection
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
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
        .sheet(isPresented: $showPaywall) {
            PaywallScreen()
        }
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("SUBSCRIPTION")
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.categoryTag)
                            .fill(Color.foyUpgradeIconBg)
                            .frame(width: 36, height: 36)
                        Image(systemName: "crown.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Color.foyOrangeAccent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Pro")
                            .font(.foyCaptionMedium)
                            .foregroundStyle(Color.foyNavy)
                        Text("Unlock all categories & features")
                            .font(.foyHint)
                            .foregroundStyle(Color.foyForegroundSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.foyPlaceholder)
                }
                .padding(Spacing.md)
            }
            .background(Color.foyUpgradeCardBg)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(Color.foyUpgradeCardBorder, lineWidth: 1)
            )
        }
    }

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

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("APPEARANCE")
            HStack(spacing: Spacing.xs) {
                ForEach(["System", "Light", "Dark"], id: \.self) { option in
                    let isSelected = selectedAppearanceOption == option
                    Button {
                        viewModel.appearanceOverride = option == "System" ? nil : option.lowercased()
                    } label: {
                        Text(option)
                            .font(.foyCaptionMedium)
                            .foregroundStyle(isSelected ? .white : Color.foyPlaceholder)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(isSelected ? Color.foyNavy : Color.foyMoodBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(Spacing.sm)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private var selectedAppearanceOption: String {
        switch viewModel.appearanceOverride {
        case "light": return "Light"
        case "dark": return "Dark"
        default: return "System"
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .foySectionLabelStyle()
            .foregroundStyle(Color.foyPlaceholder)
    }
}
