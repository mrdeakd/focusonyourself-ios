import SwiftUI

struct SettingsAppleIntelligenceSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("APPLE INTELLIGENCE")
            VStack(spacing: 0) {
                HStack {
                    Text("Apple Intelligence")
                        .font(.foyBody)
                        .foregroundStyle(Color.foyForeground)
                    Spacer()
                    FOYToggle(isOn: $viewModel.currentAppleIntelligence)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)

                Divider()
                    .background(Color.foyBorder)
                    .padding(.horizontal, Spacing.md)

                Text("After check-in, generate a personalized affirmation using on-device AI. Requires iPhone 15 Pro or newer.")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyPlaceholder)
                    .lineSpacing(Spacing.xxs)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
            }
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}
