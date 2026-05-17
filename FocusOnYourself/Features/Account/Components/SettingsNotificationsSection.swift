import SwiftUI

struct SettingsNotificationsSection: View {
    let viewModel: AccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionLabel("NOTIFICATIONS")
            HStack {
                Text("Daily 9am Reminder")
                    .font(.foyBody)
                    .foregroundStyle(Color.foyForeground)
                Spacer()
                FOYToggle(isOn: Bindable(viewModel).currentNotifications)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.foyCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}
