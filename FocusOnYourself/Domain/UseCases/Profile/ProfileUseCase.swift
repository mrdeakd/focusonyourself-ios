import Factory
import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class ProfileUseCase: ProfileUseCaseProtocol {
    private(set) var profile = UserProfile()

    @ObservationIgnored @Injected(\.userDefaultsStore) private var userDefaultsStore

    init() {
        profile = _userDefaultsStore.wrappedValue.data(for: .userProfile)
            .flatMap { try? JSONDecoder().decode(UserProfile.self, from: $0) }
            ?? UserProfile()
    }

    // MARK: - Reads

    var name: String { profile.name }
    var selectedCategories: [AffirmationCategory] { profile.selectedCategories }
    var notificationsEnabled: Bool { profile.notificationsEnabled }
    var appearanceOverride: String? { profile.appearanceOverride }
    var appleIntelligenceEnabled: Bool { profile.appleIntelligenceEnabled }
    var isAppleIntelligenceActive: Bool { profile.isAppleIntelligenceActive }
    var onboardingCompleted: Bool { profile.onboardingCompleted }

    // MARK: - Mutations

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            userDefaultsStore.setData(data, for: .userProfile)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateName(_ name: String) {
        var updated = profile
        updated.name = name
        updateProfile(updated)
    }

    func updateCategories(_ categories: [AffirmationCategory]) {
        var updated = profile
        updated.selectedCategories = categories
        updateProfile(updated)
    }

    func updateNotificationsEnabled(_ enabled: Bool) {
        var updated = profile
        updated.notificationsEnabled = enabled
        updateProfile(updated)
    }

    func updateAppearanceOverride(_ override: String?) {
        var updated = profile
        updated.appearanceOverride = override
        updateProfile(updated)
    }

    func updateAppleIntelligenceEnabled(_ enabled: Bool) {
        var updated = profile
        updated.appleIntelligenceEnabled = enabled
        updateProfile(updated)
    }

    func saveCompletedProfile(_ profile: UserProfile) {
        updateProfile(profile)
    }

    func resetAll() {
        userDefaultsStore.remove(.userProfile)
        userDefaultsStore.remove(.affirmationCache)
        userDefaultsStore.remove(.affirmationCacheDate)
        updateProfile(UserProfile())
    }
}
