import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .welcome:
                WelcomeScreen(viewModel: viewModel)
            case .name:
                NameEntryScreen(viewModel: viewModel)
            case .categories:
                CategoryPickerScreen(viewModel: viewModel)
            case .notifications:
                NotificationPermissionScreen(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed {
                appState.updateProfile(viewModel.buildProfile())
            }
        }
    }
}
