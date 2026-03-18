import SwiftUI

struct MeditationCompletionView: View {
    let sessionTitle: String
    let onDone: () -> Void

    private let completionIconSize: CGFloat = 64

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(Font.foyMeditationTimer(size: completionIconSize))
                .foregroundStyle(Color.foyOnPrimary)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text("Session Complete")
                    .font(.foyNavTitle)
                    .foregroundStyle(Color.foyOnPrimary)

                Text(sessionTitle)
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyOnPrimary.opacity(0.6))
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
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
