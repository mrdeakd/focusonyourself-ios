import SwiftUI

struct ContentView: View {
    @Environment(ProfileService.self) private var profileService

    var body: some View {
        if profileService.profile.onboardingCompleted {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}

#Preview {
    ContentView()
        .environment(ProfileService())
}
