import SwiftUI

struct SettingsResetSection: View {
    let viewModel: AccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("DATA")
            Button {
                viewModel.showResetConfirmation = true
            } label: {
                HStack {
                    Text("Reset All Progress")
                        .font(.foyBody)
                        .foregroundStyle(Color.red)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}
