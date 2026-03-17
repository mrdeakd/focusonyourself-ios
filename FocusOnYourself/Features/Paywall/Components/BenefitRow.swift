import SwiftUI

struct BenefitRow: View {
    let symbol: String
    let title: String
    let subtitle: String

    private let cardVerticalPadding: CGFloat = 10
    private let cardHorizontalPadding: CGFloat = 14
    private let hstackSpacing: CGFloat = 14

    var body: some View {
        HStack(spacing: hstackSpacing) {
            IconBox(
                systemName: symbol,
                tintColor: Color.foyNavyTint,
                iconColor: Color.foyNavy,
                size: 36,
                iconSize: 18
            )

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
        .foyCardStyle(cornerRadius: CornerRadius.card)
    }
}
