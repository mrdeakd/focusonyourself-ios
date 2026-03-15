import SwiftUI

struct BenefitRow: View {
    let symbol: String
    let title: String
    let subtitle: String

    private let iconSize: CGFloat = 18
    private let iconFrameSize: CGFloat = 36
    private let iconCornerRadius: CGFloat = 10
    private let cardVerticalPadding: CGFloat = 10
    private let cardHorizontalPadding: CGFloat = 14
    private let hstackSpacing: CGFloat = 14

    var body: some View {
        HStack(spacing: hstackSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: iconCornerRadius)
                    .fill(Color.foyNavyTint)
                    .frame(width: iconFrameSize, height: iconFrameSize)
                Image(systemName: symbol)
                    .font(.system(size: iconSize))
                    .foregroundStyle(Color.foyNavy)
            }

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.foyBodySemibold)
                    .foregroundStyle(Color.foyForeground)

                Text(subtitle)
                    .font(.foyHint)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }

            Spacer()
        }
        .padding(.vertical, cardVerticalPadding)
        .padding(.horizontal, cardHorizontalPadding)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color.foyBorder, lineWidth: 1)
        )
    }
}
