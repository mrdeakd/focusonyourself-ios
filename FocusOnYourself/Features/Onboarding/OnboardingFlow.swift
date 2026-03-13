import SwiftUI

struct OnboardingFlow: View {
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
    }
}
