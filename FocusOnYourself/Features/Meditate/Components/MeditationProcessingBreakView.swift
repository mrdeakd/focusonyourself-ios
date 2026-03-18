import SwiftUI

struct MeditationProcessingBreakView: View {
    let timerDisplay: String

    private let timerFontSize: CGFloat = 56

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(timerDisplay)
                .font(Font.foyMeditationTimer(size: timerFontSize))
                .foregroundStyle(Color.foyOnPrimary)
                .monospacedDigit()

            Text("Take a moment to reflect")
                .font(.foyCaption)
                .foregroundStyle(Color.foyOnPrimary.opacity(0.5))
        }
    }
}
