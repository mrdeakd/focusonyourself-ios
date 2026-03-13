import Foundation
import Observation

@Observable
final class SettingsViewModel {
    private let profileService: ProfileServiceProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        profileService: ProfileServiceProtocol = ServiceContainer.shared.profileService,
        notificationService: NotificationServiceProtocol = ServiceContainer.shared.notificationService
    ) {
        self.profileService = profileService
        self.notificationService = notificationService
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

    var currentAppleIntelligence: Bool {
        get { profileService.profile.appleIntelligenceEnabled }
        set {
            var profile = profileService.profile
            profile.appleIntelligenceEnabled = newValue
            profileService.updateProfile(profile)
        }
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
