import SwiftUI

struct SettingsCategoriesSection: View {
    let viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("AFFIRMATION CATEGORIES")
            VStack(spacing: 0) {
                HStack {
                    Text(viewModel.currentCategoriesSummary)
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
                    viewModel.showChangeCategoriesSheet = true
                } label: {
                    HStack {
                        Text("Change categories")
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
