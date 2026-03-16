import SwiftUI

private let cardCornerRadius: CGFloat = 16

struct InsightStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(label)
                .font(.foySectionLabel)
                .foregroundStyle(Color.foyPlaceholder)
            Text(value)
                .font(.foyStatValue)
                .foregroundStyle(Color.foyForeground)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.foyNavy, lineWidth: 1)
        )
    }
}
