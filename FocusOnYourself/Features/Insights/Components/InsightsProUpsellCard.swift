import SwiftUI

struct InsightsProUpsellCard: View {
    let viewModel: InsightsViewModel

    var body: some View {
        Button {
            viewModel.showingPaywall = true
        } label: {
            HStack(spacing: Spacing.md) {
                IconBox(
                    systemName: "chart.line.uptrend.xyaxis",
                    tintColor: Color.foyUpgradeIconBg,
                    iconColor: Color.foyOrange
                )
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("Unlock Full History")
                        .font(.foyBodyMedium)
                        .foregroundStyle(Color.foyForeground)
                    Text("30-day trends, best day & more")
                        .font(.foyCaption)
                        .foregroundStyle(Color.foyForegroundSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.foyCaptionMedium)
                    .foregroundStyle(Color.foyPlaceholder)
            }
            .padding(Spacing.md)
            .background(Color.foyUpgradeCardBg)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.calendar))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.calendar)
                    .stroke(Color.foyUpgradeCardBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
