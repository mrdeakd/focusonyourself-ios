import SwiftUI

struct StreakStatCard: View {
    let label: String
    let value: Int   // number of days

    private let valueFont = Font.custom("Inter", size: 24).weight(.medium)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(label)
                .font(.foySectionLabel)
                .foregroundStyle(Color.foyPlaceholder)
            Text("\(value) days")
                .font(valueFont)
                .foregroundStyle(Color.foyForeground)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
    }
}
