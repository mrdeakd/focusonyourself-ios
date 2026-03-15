import SwiftUI

struct StreakStatCard: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(label)
                .font(.foySectionLabel)
                .foregroundStyle(Color.foyPlaceholder)
            Text("\(value) days")
                .font(.foyStatValue)
                .foregroundStyle(Color.foyForeground)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.input)
                .stroke(Color.foyNavy, lineWidth: 1)
        )
    }
}
