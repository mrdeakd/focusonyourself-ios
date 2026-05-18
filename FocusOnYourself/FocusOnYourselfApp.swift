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
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.checkInUseCase) private var checkInUseCase
    @ObservationIgnored @Injected(\.authUseCase) private var authUseCase

    var onboardingCompleted: Bool { profileUseCase.onboardingCompleted }
    var appearanceOverride: String? { profileUseCase.appearanceOverride }

    func onSceneActive() async {
        checkInUseCase.mergeWidgetCheckIn()
        await authUseCase.refreshTokenIfNeeded()
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
    }
}
