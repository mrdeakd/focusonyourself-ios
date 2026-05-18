import Factory
import Foundation

final class ProfileUseCase: ProfileUseCaseProtocol {
    @Injected(\.profileService) private var profileService
    @Injected(\.userDefaultsService) private var userDefaultsService

    var name: String { profileService.profile.name }
    var selectedCategories: [AffirmationCategory] { profileService.profile.selectedCategories }
    var notificationsEnabled: Bool { profileService.profile.notificationsEnabled }
    var appearanceOverride: String? { profileService.profile.appearanceOverride }
    var appleIntelligenceEnabled: Bool { profileService.profile.appleIntelligenceEnabled }
    var isAppleIntelligenceActive: Bool { profileService.profile.isAppleIntelligenceActive }
    var onboardingCompleted: Bool { profileService.profile.onboardingCompleted }

    func updateName(_ name: String) {
        var profile = profileService.profile
        profile.name = name
        profileService.updateProfile(profile)
    }

    func updateCategories(_ categories: [AffirmationCategory]) {
        var profile = profileService.profile
        profile.selectedCategories = categories
        profileService.updateProfile(profile)
    }

    func updateNotificationsEnabled(_ enabled: Bool) {
        var profile = profileService.profile
        profile.notificationsEnabled = enabled
        profileService.updateProfile(profile)
    }

    func updateAppearanceOverride(_ override: String?) {
        var profile = profileService.profile
        profile.appearanceOverride = override
        profileService.updateProfile(profile)
    }

    func updateAppleIntelligenceEnabled(_ enabled: Bool) {
        var profile = profileService.profile
        profile.appleIntelligenceEnabled = enabled
        profileService.updateProfile(profile)
    }

    func saveCompletedProfile(_ profile: UserProfile) {
        profileService.updateProfile(profile)
    }

    func resetAll() {
        userDefaultsService.setData(.userProfile, value: nil)
        userDefaultsService.setData(.affirmationCache, value: nil)
        userDefaultsService.setData(.affirmationCacheDate, value: nil)
        profileService.updateProfile(UserProfile())
    }
}
