import SwiftUI

struct MeditationTimerView: View {
    let timerDisplay: String
    let phase: MeditationPhase
    let onPause: () -> Void
    let onResume: () -> Void

    private let timerFontSize: CGFloat = 56

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(timerDisplay)
                .font(Font.foyMeditationTimer(size: timerFontSize))
                .foregroundStyle(Color.foyOnPrimary)
                .monospacedDigit()

            Text("Breathe and rest")
                .font(.foyCaption)
                .foregroundStyle(Color.foyOnPrimary.opacity(0.5))

            Button {
                if phase == .timerRunning {
                    onPause()
                } else {
                    onResume()
                }
            } label: {
                Image(systemName: phase == .timerRunning ? "pause.circle" : "play.circle")
                    .font(Font.foyMeditationTimer(size: timerFontSize))
                    .foregroundStyle(Color.foyOnPrimary.opacity(0.8))
            }
            .accessibilityLabel(phase == .timerRunning ? "Pause" : "Resume")
        }
    }
}
