import Factory
import Foundation
import Observation
import WidgetKit

@Observable
final class ProfileService: ProfileServiceProtocol {
    private(set) var profile = UserProfile()

    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService

    init() {
        profile = userDefaultsService.getData(.userProfile)
            .flatMap { try? JSONDecoder().decode(UserProfile.self, from: $0) }
            ?? UserProfile()
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            userDefaultsService.setData(.userProfile, value: data)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
