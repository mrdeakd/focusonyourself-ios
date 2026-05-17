import SwiftUI

struct SettingsDailyContextSection: View {
    let viewModel: AccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("DAILY CONTEXT")
            VStack(spacing: 0) {
                HStack {
                    Text(viewModel.activeFactorSummary)
                        .font(.foyHint)
                        .foregroundStyle(Color.foyForegroundSecondary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

                Rectangle()
                    .fill(Color.foyBorder)
                    .frame(height: 1)

                Button {
                    viewModel.showDailyContextSheet = true
                } label: {
                    HStack {
                        Text("Manage factors")
                            .font(.foyCaptionMedium)
                            .foregroundStyle(Color.foyNavy)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}
