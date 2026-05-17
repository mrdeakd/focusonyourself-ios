import SwiftUI

struct SignUpScreen: View {
    @Bindable var viewModel: AuthViewModel
    let onSwitchToSignIn: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock
                    formBlock
                }
                .padding(.top, Spacing.lg)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.sm)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            bottomBlock
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.screenBottom)
                .padding(.top, Spacing.sm)
                .background(Color.foyBackground)
        }
        .ignoresSafeArea(.keyboard)
    }

    private var titleBlock: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Create Account")
                    .font(.foyHeadline)
                    .foregroundStyle(Color.foyForeground)
                Text("Join FocusOnYourself to sync your progress across devices.")
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
            if let error = viewModel.error {
                InlineErrorView(error: error)
            }

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
        }
    }

    private var bottomBlock: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Task { await viewModel.register() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.foyOnPrimary)
                    } else {
                        Text("Create Account")
                            .font(.foyButtonLabel)
                    }
                }
                .foregroundStyle(Color.foyOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.inputHeight)
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
