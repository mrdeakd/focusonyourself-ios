import SwiftUI

struct SettingsNameSection: View {
    let viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("YOUR NAME")
            VStack(spacing: 0) {
                HStack {
                    Text(viewModel.currentName.isEmpty ? "Your name" : viewModel.currentName)
                        .font(.foyBody)
                        .foregroundStyle(viewModel.currentName.isEmpty ? Color.foyPlaceholder : Color.foyForeground)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

                Rectangle()
                    .fill(Color.foyBorder)
                    .frame(height: 1)

                Button {
                    viewModel.showChangeNameSheet = true
                } label: {
                    HStack {
                        Text("Change name")
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
