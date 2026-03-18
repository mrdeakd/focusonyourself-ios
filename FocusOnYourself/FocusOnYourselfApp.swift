import Factory
import SwiftUI

@main
struct FocusOnYourselfApp: App {
    init() {
        applyStoredLanguageIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(Container.shared.profileService())
        }
    }

    private func applyStoredLanguageIfNeeded() {
        guard
            let data = UserDefaults(suiteName: AppGroup.suiteName)?.data(forKey: "userProfile")
                ?? UserDefaults.standard.data(forKey: "userProfile"),
            let profile = try? JSONDecoder().decode(UserProfile.self, from: data),
            let code = profile.preferredLanguage
        else { return }
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
    }
}

private struct AppRootView: View {
    @Environment(ProfileService.self) private var profileService

    private var preferredColorScheme: ColorScheme? {
        switch profileService.profile.appearanceOverride {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        ContentView()
            .preferredColorScheme(preferredColorScheme)
    }
}
