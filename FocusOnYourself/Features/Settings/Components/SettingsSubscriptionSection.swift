import SwiftUI

struct SettingsSubscriptionSection: View {
    @Binding var showPaywall: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("SUBSCRIPTION")
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.categoryTag)
                            .fill(Color.foyUpgradeIconBg)
                            .frame(width: 36, height: 36)
                        Image(systemName: "crown.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Color.foyOrangeAccent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Pro")
                            .font(.foyCaptionMedium)
                            .foregroundStyle(Color.foyNavy)
                        Text("Unlock all categories & features")
                            .font(.foyHint)
                            .foregroundStyle(Color.foyForegroundSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.foyPlaceholder)
                }
                .padding(Spacing.md)
            }
            .background(Color.foyUpgradeCardBg)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(Color.foyUpgradeCardBorder, lineWidth: 1)
            )
        }
    }
}
