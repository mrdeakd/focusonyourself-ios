import SwiftUI

struct AuthFlow: View {
    @Environment(\.dismiss) private var dismissAction
    @State private var viewModel = AuthViewModel()
    @State private var tab: Tab = .signIn

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
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            if isAuth { dismissAction() }
        }
        .onChange(of: tab) { viewModel.error = nil }
    }
}
