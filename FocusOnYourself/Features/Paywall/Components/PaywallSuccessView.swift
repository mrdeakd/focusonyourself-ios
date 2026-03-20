import SwiftUI

struct PaywallSuccessView: View {
    let onContinue: () -> Void

    private let iconSize: CGFloat = 64

    var body: some View {
        ZStack {
            Color.foyNavy.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(Font.foyMeditationTimer(size: iconSize))
                    .foregroundStyle(Color.foyOnPrimary)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.xs) {
                    Text("You're now Pro!")
                        .font(.foyHeadline)
                        .foregroundStyle(Color.foyOnPrimary)

                    Text("Enjoy all features. Thank you for your support.")
                        .font(.foyCaption)
                        .foregroundStyle(Color.foyOnPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.foyButtonLabel)
                        .foregroundStyle(Color.foyNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.buttonVertical)
                        .background(Color.foyOnPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}
