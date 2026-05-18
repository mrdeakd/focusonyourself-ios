import Factory
import Foundation

final class ProfileRepositoryImpl: ProfileRepositoryProtocol {
    @Injected(\.profileService) private var profileService
    @Injected(\.userDefaultsService) private var userDefaultsService

    func update(_ profile: UserProfile) {
        profileService.updateProfile(profile)
    }

    func resetAll() {
        userDefaultsService.setData(.userProfile, value: nil)
        userDefaultsService.setData(.affirmationCache, value: nil)
        userDefaultsService.setData(.affirmationCacheDate, value: nil)
        profileService.updateProfile(UserProfile())
    }
}
