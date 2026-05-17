import SwiftUI

struct SignInScreen: View {
    @Bindable var viewModel: AuthViewModel
    let onSwitchToSignUp: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                titleBlock
                formBlock
                Spacer(minLength: Spacing.xxl)
                bottomBlock
            }
            .padding(.top, Spacing.lg)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.screenBottom)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var titleBlock: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Sign In")
                    .font(.foyHeadline)
                    .foregroundStyle(Color.foyForeground)
                Text("Welcome back to FocusOnYourself.")
                    .foyBodyStyle()
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.foyBodyMedium)
                    .foregroundStyle(Color.foyForeground)
                    .frame(width: 32, height: 32)
                    .background(Color.foyCard)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
        }
    }

    private var formBlock: some View {
        VStack(spacing: Spacing.sm) {
            TextField("Email", text: $viewModel.email)
                .font(.foyInputText)
                .foregroundStyle(Color.foyForeground)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, Spacing.md)
                .frame(height: Spacing.inputHeight)
                .background(Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
                .overlay { RoundedRectangle(cornerRadius: CornerRadius.input).stroke(Color.foyBorder, lineWidth: 1) }

            SecureField("Password", text: $viewModel.password)
                .font(.foyInputText)
                .foregroundStyle(Color.foyForeground)
                .textContentType(.password)
                .padding(.horizontal, Spacing.md)
                .frame(height: Spacing.inputHeight)
                .background(Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
                .overlay { RoundedRectangle(cornerRadius: CornerRadius.input).stroke(Color.foyBorder, lineWidth: 1) }

            if let error = viewModel.error {
                InlineErrorView(error: error)
            }
        }
    }

    private var bottomBlock: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Task { await viewModel.signIn() }
            } label: {
                Text("Sign In")
                    .font(.foyButtonLabel)
                    .foregroundStyle(Color.foyOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.buttonVertical)
                    .background(canSubmit ? Color.foyNavy : Color.foyButtonDisabled)
                    .clipShape(Capsule())
            }
            .disabled(!canSubmit || viewModel.isLoading)

            Button(action: onSwitchToSignUp) {
                Text("No account? Create one")
                    .font(.foyBodyMedium)
                    .foregroundStyle(Color.foyNavy)
                    .padding(.vertical, Spacing.sm)
            }
        }
    }

    private var canSubmit: Bool {
        !viewModel.email.isEmpty && !viewModel.password.isEmpty
    }
}
