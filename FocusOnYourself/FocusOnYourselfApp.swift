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
    @Environment(\.scenePhase) private var scenePhase

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
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    profileService.mergeWidgetCheckIn()
                }
            }
    }
}
