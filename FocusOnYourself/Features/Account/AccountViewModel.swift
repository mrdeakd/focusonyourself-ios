import Factory
import Foundation
import FoundationModels
import Observation

@Observable @MainActor
final class AccountViewModel {
    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.notificationService) private var notificationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService
    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService
    @ObservationIgnored @Injected(\.authUseCase) private var authUseCase
    @ObservationIgnored @Injected(\.profileRepository) private var profileRepository

    var isAuthenticated: Bool
    var isRefreshing = false
    var accountEmail: String?
    var showAuthFlow = false
    var showSettingsSheet = false
    var isPro: Bool { purchaseService.isPro }

    init() {
        isAuthenticated = _authUseCase.wrappedValue.isAuthenticated
        accountEmail = _authUseCase.wrappedValue.email
    }

    func signOut() async {
        await authUseCase.signOut()
        isAuthenticated = false
        accountEmail = nil
    }

    func refreshAuthState() async {
        guard authUseCase.isAuthenticated, !isAuthenticated else { return }
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(350))
        isAuthenticated = true
        accountEmail = authUseCase.email
        isRefreshing = false
    }

    var currentName: String {
        profileService.profile.name
    }

    var currentCategories: Set<AffirmationCategory> {
        Set(profileService.profile.selectedCategories)
    }

    var currentNotifications: Bool {
        get { profileService.profile.notificationsEnabled }
        set {
            var updated = profileService.profile
            updated.notificationsEnabled = newValue
            profileService.updateProfile(updated)
            if newValue {
                notificationService.schedule(name: profileService.profile.name)
            } else {
                notificationService.cancel()
            }
        }
    }

    var appearanceOverride: String? {
        get { profileService.profile.appearanceOverride }
        set {
            var updated = profileService.profile
            updated.appearanceOverride = newValue
            profileService.updateProfile(updated)
        }
    }

    var currentAppleIntelligence: Bool {
        get { profileService.profile.appleIntelligenceEnabled }
        set {
            var updated = profileService.profile
            updated.appleIntelligenceEnabled = newValue
            profileService.updateProfile(updated)
        }
    }

    var isAppleIntelligenceAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func updateName(_ name: String) {
        var updated = profileService.profile
        updated.name = name
        profileService.updateProfile(updated)
    }

    func updateCategories(_ categories: Set<AffirmationCategory>) {
        var updated = profileService.profile
        updated.selectedCategories = Array(categories)
        profileService.updateProfile(updated)
    }

    var showChangeNameSheet = false
    var showChangeCategoriesSheet = false
    var showDailyContextSheet = false
    var showPaywall = false
    var showResetConfirmation = false

    var sortedCategories: [AffirmationCategory] {
        AffirmationCategory.allCases.sorted { $0.isFree && !$1.isFree }
    }

    var currentCategoriesSummary: String {
        currentCategories.map(\.displayName).sorted().joined(separator: ", ")
    }

    func resetAllData() async {
        profileRepository.resetAll()
        notificationService.cancel()
        userDefaultsService.setLocalBool(.showSleepFactor, value: true)
        userDefaultsService.setLocalBool(.showStressFactor, value: true)
        userDefaultsService.setLocalBool(.showExerciseFactor, value: true)
        userDefaultsService.setLocalBool(.showSocialFactor, value: true)
        userDefaultsService.clearLocalData(.pendingWidgetCheckIn)
        await authUseCase.signOut()
        await purchaseService.refreshEntitlements()
        isAuthenticated = false
        accountEmail = nil
    }

    var showSleepFactor: Bool {
        get { userDefaultsService.getLocalBool(.showSleepFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showSleepFactor, value: newValue) }
    }

    var showStressFactor: Bool {
        get { userDefaultsService.getLocalBool(.showStressFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showStressFactor, value: newValue) }
    }

    var showExerciseFactor: Bool {
        get { userDefaultsService.getLocalBool(.showExerciseFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showExerciseFactor, value: newValue) }
    }

    var showSocialFactor: Bool {
        get { userDefaultsService.getLocalBool(.showSocialFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showSocialFactor, value: newValue) }
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
}
