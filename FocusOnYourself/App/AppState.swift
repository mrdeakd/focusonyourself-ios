import Foundation
import Observation

@Observable
final class AppState {
    var profile: UserProfile

    init() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = saved
        } else {
            self.profile = UserProfile()
        }
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }
}
