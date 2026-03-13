import SwiftUI

struct StreakStatCard: View {
    let label: String
    let value: Int   // number of days

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.inter(11, weight: .medium))
                .foregroundStyle(Color.foyPlaceholder)
            Text("\(value) days")
                .font(.inter(24, weight: .medium))
                .foregroundStyle(Color.foyForeground)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
