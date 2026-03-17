import SwiftUI

struct StatCard: View {
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
        .foyCardStyle(borderColor: .foyNavy)
    }
}
