import Factory
import SwiftUI

struct AuthFlow: View {
    @State private var viewModel = AuthViewModel()
    @State private var tab: Tab = .signIn

    @ObservationIgnored @Injected(\.authService) private var authService

    private enum Tab { case signIn, createAccount }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()
            switch tab {
            case .signIn:
                SignInScreen(viewModel: viewModel, onSwitchToSignUp: { tab = .createAccount })
            case .createAccount:
                SignUpScreen(viewModel: viewModel, onSwitchToSignIn: { tab = .signIn })
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth { dismissAction() }
        }
    }

    @Environment(\.dismiss) private var dismissAction
}
