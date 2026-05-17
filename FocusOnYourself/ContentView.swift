import SwiftUI

struct ContentView: View {
    var onboardingCompleted: Bool

    var body: some View {
        if onboardingCompleted {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    ContentView(onboardingCompleted: true)
}
