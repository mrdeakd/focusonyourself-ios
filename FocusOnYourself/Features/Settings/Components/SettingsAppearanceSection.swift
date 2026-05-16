import SwiftUI

struct SettingsAppearanceSection: View {
    let viewModel: SettingsViewModel

    private var selectedAppearanceOption: String {
        switch viewModel.appearanceOverride {
        case "light": return "Light"
        case "dark": return "Dark"
        default: return "System"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("APPEARANCE")
            HStack(spacing: Spacing.xs) {
                ForEach(["System", "Light", "Dark"], id: \.self) { option in
                    let isSelected = selectedAppearanceOption == option
                    Button {
                        viewModel.appearanceOverride = option == "System" ? nil : option.lowercased()
                    } label: {
                        Text(option)
                            .font(.foyCaptionMedium)
                            .foregroundStyle(isSelected ? Color.foyOnPrimary : Color.foyPlaceholder)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(isSelected ? Color.foyNavy : Color.foyMoodBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(Spacing.sm)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}
