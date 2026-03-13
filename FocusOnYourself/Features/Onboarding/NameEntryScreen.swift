import SwiftUI

struct NameEntryScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    private let headerInternalGap: CGFloat = 10
    private let inputBorderWidth: CGFloat = 1.5

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: headerInternalGap) {
                        Text("What should\nwe call you?")
                            .foySectionTitleStyle()
                            .foregroundStyle(Color.foyForeground)
                        Text("We'll use your name to personalize\nyour daily greetings.")
                            .foyBodyStyle()
                            .foregroundStyle(Color.foyForegroundSecondary)
                    }

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CornerRadius.input)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.input)
                                    .stroke(Color.foyBorder, lineWidth: inputBorderWidth)
                            )
                        if viewModel.nameInput.isEmpty {
                            Text("Your name")
                                .font(.foyInputText)
                                .foregroundStyle(Color.foyPlaceholder)
                                .padding(.horizontal, Spacing.md)
                        }
                        TextField("", text: $viewModel.nameInput)
                            .font(.foyInputText)
                            .foregroundStyle(Color.foyForeground)
                            .padding(.horizontal, Spacing.md)
                            .submitLabel(.done)
                            .onSubmit { if viewModel.isNameValid { viewModel.advance() } }
                    }
                    .frame(height: Spacing.inputHeight)
                }

                Spacer()

                VStack(spacing: Spacing.xs) {
                    Button { viewModel.advance() } label: {
                        Text("Continue")
                            .font(.foyButtonLabel)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.buttonVertical)
                            .background(viewModel.isNameValid ? Color.foyNavy : Color.foyButtonDisabled)
                            .clipShape(Capsule())
                    }
                    .disabled(!viewModel.isNameValid)

                    Text("Enter your name to continue")
                        .font(.foyHint)
                        .foregroundStyle(Color.foyPlaceholder)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.top, Spacing.screenTop)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.screenBottom)
        }
    }
}

#Preview { NameEntryScreen(viewModel: OnboardingViewModel()) }
