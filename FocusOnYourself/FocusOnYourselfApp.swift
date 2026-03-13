import SwiftUI

@main
struct FocusOnYourselfApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(ServiceContainer.shared.profileService)
        }
    }
}
