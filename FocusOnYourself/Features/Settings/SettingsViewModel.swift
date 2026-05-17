import Factory
import Foundation
import FoundationModels
import Observation

@Observable @MainActor
final class SettingsViewModel {
    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.notificationService) private var notificationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService
    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService
    @ObservationIgnored @Injected(\.authService) private var authService

    var isAuthenticated: Bool { authService.isAuthenticated }
    var accountEmail: String? { authService.userEmail }
    var showAuthFlow = false
    var showSettingsSheet = false

    func signOut() async {
        await authService.signOut()
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
            var profile = profileService.profile
            profile.notificationsEnabled = newValue
            profileService.updateProfile(profile)
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
            var profile = profileService.profile
            profile.appearanceOverride = newValue
            profileService.updateProfile(profile)
        }
    }

    var currentAppleIntelligence: Bool {
        get { profileService.profile.appleIntelligenceEnabled }
        set {
            var profile = profileService.profile
            profile.appleIntelligenceEnabled = newValue
            profileService.updateProfile(profile)
        }
    }

    var isPro: Bool { purchaseService.isPro }

    var isAppleIntelligenceAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func updateName(_ name: String) {
        var profile = profileService.profile
        profile.name = name
        profileService.updateProfile(profile)
    }

    func updateCategories(_ categories: Set<AffirmationCategory>) {
        var profile = profileService.profile
        profile.selectedCategories = Array(categories)
        profileService.updateProfile(profile)
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

    func resetAllData() {
        profileService.resetAllData()
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
