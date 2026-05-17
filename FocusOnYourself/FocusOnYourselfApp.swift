import Factory
import SwiftUI

@main
struct FocusOnYourselfApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

@Observable
@MainActor
private final class AppRootViewModel {
    @ObservationIgnored @Injected(\.authService) private var authService
    @ObservationIgnored @Injected(\.profileService) private var profileService

    var onboardingCompleted: Bool
    var appearanceOverride: String?

    init() {
        let profile = _profileService.wrappedValue.profile
        onboardingCompleted = profile.onboardingCompleted
        appearanceOverride = profile.appearanceOverride
    }

    func onSceneActive() async {
        profileService.mergeWidgetCheckIn()
        await authService.refreshTokenIfNeeded()
    }

    func observeProfile() async {
        for await profile in profileService.profileUpdates() {
            onboardingCompleted = profile.onboardingCompleted
            appearanceOverride = profile.appearanceOverride
        }
    }
}

private struct AppRootView: View {
    @State private var viewModel = AppRootViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private var preferredColorScheme: ColorScheme? {
        switch viewModel.appearanceOverride {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        ContentView(onboardingCompleted: viewModel.onboardingCompleted)
            .preferredColorScheme(preferredColorScheme)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel.onSceneActive() }
                }
            }
            .task { await viewModel.observeProfile() }
    }
}
