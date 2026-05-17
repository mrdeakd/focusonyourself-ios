import SwiftUI

// Pencil design node: K7zfZG
struct SignUpScreen: View {
    @Bindable var viewModel: AuthViewModel
    let onSwitchToSignIn: () -> Void

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: Spacing.lg) {
                    titleBlock
                    formBlock
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, Spacing.screenTop)

                bottomBlock
                    .padding(.bottom, Spacing.screenBottom)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Create Account")
                .font(.foyHeadline)
                .foregroundStyle(Color.foyForeground)
            Text("Join FocusOnYourself to sync your progress across devices.")
                .foyBodyStyle()
                .foregroundStyle(Color.foyForegroundSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .textContentType(.newPassword)
                .padding(.horizontal, Spacing.md)
                .frame(height: Spacing.inputHeight)
                .background(Color.foyCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
                .overlay { RoundedRectangle(cornerRadius: CornerRadius.input).stroke(Color.foyBorder, lineWidth: 1) }

            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .font(.foyInputText)
                .foregroundStyle(Color.foyForeground)
                .textContentType(.newPassword)
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
                Task { await viewModel.register() }
            } label: {
                Text("Create Account")
                    .font(.foyButtonLabel)
                    .foregroundStyle(Color.foyOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.buttonVertical)
                    .background(canSubmit ? Color.foyNavy : Color.foyButtonDisabled)
                    .clipShape(Capsule())
            }
            .disabled(!canSubmit || viewModel.isLoading)

            Button(action: onSwitchToSignIn) {
                Text("Already have an account? Sign in")
                    .font(.foyBodyMedium)
                    .foregroundStyle(Color.foyNavy)
                    .padding(.vertical, Spacing.sm)
            }
        }
    }

    private var canSubmit: Bool {
        !viewModel.email.isEmpty && !viewModel.password.isEmpty && !viewModel.confirmPassword.isEmpty
    }
}
