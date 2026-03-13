import SwiftUI

struct WelcomeScreen: View {
    var viewModel: OnboardingViewModel

    private let heroTopPadding: CGFloat = 60

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.foyNavyTint)
                            .frame(width: Spacing.iconCircle, height: Spacing.iconCircle)
                        Image(systemName: "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: Spacing.iconImage, height: Spacing.iconImage)
                            .foregroundStyle(Color.foyNavy)
                    }
                    Text("Focus On Yourself")
                        .foyDisplayTitleStyle()
                        .foregroundStyle(Color.foyForeground)
                        .multilineTextAlignment(.center)
                    Text("A daily moment of intention.")
                        .foyBodyStyle()
                        .foregroundStyle(Color.foyForegroundSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, heroTopPadding)

                Spacer()

                Button { viewModel.advance() } label: {
                    Text("Get Started")
                        .font(.foyButtonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.buttonVertical)
                        .background(Color.foyNavy)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.screenBottom)
        }
    }
}

#Preview { WelcomeScreen(viewModel: OnboardingViewModel()) }
