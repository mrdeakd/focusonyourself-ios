import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.profile.onboardingCompleted {
            Text("Main App — Coming Soon")
                .foregroundStyle(Color.foyForegroundSecondary)
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
