import Factory
import SwiftUI

@main
struct FocusOnYourselfApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(Container.shared.profileService())
        }
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
