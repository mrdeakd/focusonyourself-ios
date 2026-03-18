import Factory
import Foundation
import FoundationModels
import Observation

@Observable @MainActor
final class SettingsViewModel {
    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.notificationService) private var notificationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService

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
}
