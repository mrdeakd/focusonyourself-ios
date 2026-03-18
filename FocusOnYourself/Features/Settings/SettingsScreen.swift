import SwiftUI

struct SettingsScreen: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showChangeNameSheet = false
    private let badgePaddingH: CGFloat = 10
    @State private var showChangeCategoriesSheet = false
    @State private var showPaywall = false
    @State private var showLanguageRestartAlert = false
    @State private var pendingLanguageCode: String = ""

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("settings.title")
                        .font(.foyNavTitle)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                    Text(viewModel.isPro ? "PRO" : "FREE")
                        .font(.foySectionLabelSemibold)
                        .foregroundStyle(viewModel.isPro ? Color.foyOrangeAccent : Color.foyNavy)
                        .padding(.horizontal, badgePaddingH)
                        .padding(.vertical, Spacing.xxxs)
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
                        languageSection
                        if viewModel.isAppleIntelligenceAvailable && viewModel.isPro {
                            appleIntelligenceSection
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.lg)
                }
                .scrollIndicators(.hidden)
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
        .alert(String(localized: "settings.language.restartAlertTitle"), isPresented: $showLanguageRestartAlert) {
            Button(String(localized: "settings.language.ok")) {
                viewModel.changeLanguage(pendingLanguageCode)
            }
            Button(String(localized: "settings.language.cancel"), role: .cancel) { }
        } message: {
            Text("settings.language.restartAlertMessage")
        }
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(String(localized: "settings.subscription"))
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
                        Text("settings.upgradeToPro")
                            .font(.foyCaptionMedium)
                            .foregroundStyle(Color.foyNavy)
                        Text("settings.unlockFeatures")
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
            SectionLabel(String(localized: "settings.yourName"))
            VStack(spacing: 0) {
                HStack {
                    Text(viewModel.currentName.isEmpty
                         ? String(localized: "settings.yourNamePlaceholder")
                         : viewModel.currentName)
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
                        Text("settings.changeName")
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
            SectionLabel(String(localized: "settings.affirmationCategories"))
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
                        Text("settings.changeCategories")
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
            SectionLabel(String(localized: "settings.notifications"))
            HStack {
                Text("settings.dailyReminder")
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
            SectionLabel(String(localized: "settings.appearance"))
            HStack(spacing: Spacing.xs) {
                ForEach([("System", String(localized: "settings.appearance.system")),
                         ("Light", String(localized: "settings.appearance.light")),
                         ("Dark", String(localized: "settings.appearance.dark"))], id: \.0) { id, label in
                    let isSelected = selectedAppearanceOption == id
                    Button {
                        viewModel.appearanceOverride = id == "System" ? nil : id.lowercased()
                    } label: {
                        Text(label)
                            .font(.foyCaptionMedium)
                            .foregroundStyle(isSelected ? Color.foyOnPrimary : Color.foyPlaceholder)
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

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(String(localized: "settings.language"))
            HStack(spacing: Spacing.xs) {
                ForEach([("en", "English"), ("hu", "Magyar")], id: \.0) { code, label in
                    let isSelected = viewModel.currentLanguage == code
                    Button {
                        guard code != viewModel.currentLanguage else { return }
                        pendingLanguageCode = code
                        showLanguageRestartAlert = true
                    } label: {
                        Text(label)
                            .font(.foyCaptionMedium)
                            .foregroundStyle(isSelected ? Color.foyOnPrimary : Color.foyPlaceholder)
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

    private var appleIntelligenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel(String(localized: "settings.appleIntelligence"))
            VStack(spacing: 0) {
                HStack {
                    Text("settings.appleIntelligenceToggle")
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

                Text("settings.appleIntelligenceHint")
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
}
