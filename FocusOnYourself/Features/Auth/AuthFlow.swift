import Factory
import SwiftUI

// Pencil design node: itjn7
struct AuthFlow: View {
    @State private var viewModel = AuthViewModel()
    @State private var tab: Tab = .signIn
    @Environment(\.dismiss) private var dismiss

    @ObservationIgnored @Injected(\.authService) private var authService

    private enum Tab { case signIn, createAccount }

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                SheetDragHandle()
                tabPicker
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.sm)

                switch tab {
                case .signIn:
                    SignInScreen(viewModel: viewModel, onSwitchToSignUp: { tab = .createAccount })
                case .createAccount:
                    SignUpScreen(viewModel: viewModel, onSwitchToSignIn: { tab = .signIn })
                }
            }
        }
        .presentationBackground(Color.foyBackground)
        .presentationDragIndicator(.hidden)
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth { dismiss() }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: Spacing.xxs) {
            tabButton("Sign In", isActive: tab == .signIn) { tab = .signIn }
            tabButton("Create Account", isActive: tab == .createAccount) { tab = .createAccount }
        }
        .padding(Spacing.xxs)
        .background(Color.foyMoodBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private func tabButton(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.foyCaptionMedium)
                .foregroundStyle(isActive ? Color.foyOnPrimary : Color.foyForegroundSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(isActive ? Color.foyNavy : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.xs))
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
        }
        .buttonStyle(.plain)
    }
}
