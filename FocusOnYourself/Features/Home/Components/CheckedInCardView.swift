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
        .foyCardStyle()
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
                    Image(mood.imageName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.primary)
                    Text(mood.displayName)
                        .font(.foyHintMedium)
                        .foregroundStyle(Color.foyNavy)
                }
                .padding(.vertical, Spacing.xxs)
                .padding(.horizontal, Spacing.sm)
                .background(Color.foyNavyTint)
                .clipShape(Capsule())
            }
        }
        .alignmentGuide(.firstTextBaseline) { dims in dims[.firstTextBaseline] }
    }
}
