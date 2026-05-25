import Factory
import Foundation
import FoundationModels
import Observation

@Observable @MainActor
final class AccountViewModel {
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.notificationsUseCase) private var notificationsUseCase
    @ObservationIgnored @Injected(\.purchaseUseCase) private var purchaseUseCase
    @ObservationIgnored @Injected(\.settingsUseCase) private var settingsUseCase
    @ObservationIgnored @Injected(\.authUseCase) private var authUseCase

    // MARK: - State

    var showAuthFlow = false
    var showSettingsSheet = false
    var showChangeNameSheet = false
    var showChangeCategoriesSheet = false
    var showDailyContextSheet = false
    var showPaywall = false
    var showResetConfirmation = false

    // MARK: - Computed

    var isAuthenticated: Bool { authUseCase.isAuthenticated }
    var accountEmail: String? { authUseCase.email }
    var isPro: Bool { purchaseUseCase.isPro }

    var currentName: String {
        profileUseCase.name
    }

    var currentCategories: Set<AffirmationCategory> {
        Set(profileUseCase.selectedCategories)
    }

    var currentNotifications: Bool {
        get { profileUseCase.notificationsEnabled }
        set { notificationsUseCase.setEnabled(newValue) }
    }

    var appearanceOverride: String? {
        get { profileUseCase.appearanceOverride }
        set { profileUseCase.updateAppearanceOverride(newValue) }
    }

    var currentAppleIntelligence: Bool {
        get { profileUseCase.appleIntelligenceEnabled }
        set { profileUseCase.updateAppleIntelligenceEnabled(newValue) }
    }

    var isAppleIntelligenceAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    var sortedCategories: [AffirmationCategory] {
        AffirmationCategory.allCases.sorted { $0.isFree && !$1.isFree }
    }

    var currentCategoriesSummary: String {
        currentCategories.map(\.displayName).sorted().joined(separator: ", ")
    }

    var showSleepFactor: Bool {
        get { settingsUseCase.showSleepFactor }
        set { settingsUseCase.showSleepFactor = newValue }
    }

    var showStressFactor: Bool {
        get { settingsUseCase.showStressFactor }
        set { settingsUseCase.showStressFactor = newValue }
    }

    var showExerciseFactor: Bool {
        get { settingsUseCase.showExerciseFactor }
        set { settingsUseCase.showExerciseFactor = newValue }
    }

    var showSocialFactor: Bool {
        get { settingsUseCase.showSocialFactor }
        set { settingsUseCase.showSocialFactor = newValue }
    }

    var activeFactorSummary: String {
        let labels = [
            showSleepFactor    ? "Sleep" : nil,
            showStressFactor   ? "Stress" : nil,
            showExerciseFactor ? "Exercise" : nil,
            showSocialFactor   ? "Social" : nil
        ].compactMap { $0 }
        return labels.isEmpty ? "None" : labels.joined(separator: ", ")
    }

    // MARK: - Public methods

    func signOut() async {
        await authUseCase.signOut()
    }

    func updateName(_ name: String) {
        profileUseCase.updateName(name)
    }

    func updateCategories(_ categories: Set<AffirmationCategory>) {
        profileUseCase.updateCategories(Array(categories))
    }

    func resetAllData() async {
        profileUseCase.resetAll()
        notificationsUseCase.cancel()
        settingsUseCase.resetFactorToggles()
        settingsUseCase.clearPendingWidgetCheckIn()
        await authUseCase.signOut()
        await purchaseUseCase.refreshEntitlements()
    }
}
