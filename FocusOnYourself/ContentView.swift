import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.profile.onboardingCompleted {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
