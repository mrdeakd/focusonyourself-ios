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
    @ObservationIgnored @Injected(\.authService) private var authService
    @ObservationIgnored @Injected(\.keychainService) private var keychain

    var isAuthenticated: Bool
    var isRefreshing = false
    var accountEmail: String?
    var showAuthFlow = false
    var showSettingsSheet = false
    var isPro: Bool
    private var profile = UserProfile()

    init() {
        let token = _keychain.wrappedValue.load(key: KeychainService.accessTokenKey)
        isAuthenticated = token.map { !$0.isEmpty } ?? false
        accountEmail = _keychain.wrappedValue.load(key: KeychainService.userEmailKey)
        isPro = _purchaseService.wrappedValue.isPro
        profile = _profileService.wrappedValue.profile
    }

    func observeProfile() async {
        for await updated in profileService.profileUpdates() {
            profile = updated
        }
    }

    func observeIsPro() async {
        for await updated in purchaseService.isProUpdates() {
            isPro = updated
        }
    }

    func signOut() async {
        await authService.signOut()
        isAuthenticated = false
        accountEmail = nil
    }

    func refreshAuthState() async {
        let token = keychain.load(key: KeychainService.accessTokenKey)
        guard token.map({ !$0.isEmpty }) ?? false, !isAuthenticated else { return }
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(350))
        isAuthenticated = true
        accountEmail = keychain.load(key: KeychainService.userEmailKey)
        isRefreshing = false
    }

    var currentName: String {
        profile.name
    }

    var currentCategories: Set<AffirmationCategory> {
        Set(profile.selectedCategories)
    }

    var currentNotifications: Bool {
        get { profile.notificationsEnabled }
        set {
            var updated = profile
            updated.notificationsEnabled = newValue
            profileService.updateProfile(updated)
            if newValue {
                notificationService.schedule(name: profile.name)
            } else {
                notificationService.cancel()
            }
        }
    }

    var appearanceOverride: String? {
        get { profile.appearanceOverride }
        set {
            var updated = profile
            updated.appearanceOverride = newValue
            profileService.updateProfile(updated)
        }
    }

    var currentAppleIntelligence: Bool {
        get { profile.appleIntelligenceEnabled }
        set {
            var updated = profile
            updated.appleIntelligenceEnabled = newValue
            profileService.updateProfile(updated)
        }
    }

    var isAppleIntelligenceAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func updateName(_ name: String) {
        var updated = profile
        updated.name = name
        profileService.updateProfile(updated)
    }

    func updateCategories(_ categories: Set<AffirmationCategory>) {
        var updated = profile
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

    func resetAllData() {
        profileService.resetAllData()
    }

    #if DEBUG
    var isProDebugOverride: Bool {
        get { userDefaultsService.getBool(.isProDebugOverride) }
        set {
            userDefaultsService.setBool(.isProDebugOverride, value: newValue)
            Task { await purchaseService.refreshEntitlements() }
        }
    }
    #endif

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
