import SwiftUI

struct CheckedInCardView: View {
    let mood: Mood?
    let streakCount: Int

    private let flameSize: CGFloat = 14

    var body: some View {
        VStack(spacing: Spacing.md) {
            successRow
            moodSummaryRow
        }
        .padding(Spacing.lg)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.input)
                .stroke(Color.foyBorder, lineWidth: 1)
        )
    }

    private var successRow: some View {
        HStack(spacing: Spacing.xs) {
            Text("Check-in complete for today!")
                .font(.foyCaptionMedium)
                .foregroundStyle(Color.foyForeground)
            Spacer()
        }
    }

    private var moodSummaryRow: some View {
        HStack(spacing: Spacing.sm) {
            Text("Your mood today")
                .font(.foyHint)
                .foregroundStyle(Color.foyPlaceholder)
            Spacer()
            if let mood {
                HStack(spacing: Spacing.xxs) {
                    Text(mood.emoji)
                        .font(.foySkipLabel)
                    Text(mood.displayName)
                        .font(.foyHintMedium)
                        .foregroundStyle(Color.foyNavy)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, Spacing.sm)
                .background(Color.foyNavyTint)
                .clipShape(Capsule())
            }
        }
        .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
    }
}
