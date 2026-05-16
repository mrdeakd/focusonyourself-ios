import SwiftUI

struct PaywallDismissButton: View {
    @Environment(\.dismiss) private var dismiss

    private let background = Color.foyMoodBackground

    var body: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(background)
                    .frame(width: Spacing.xxl, height: Spacing.xxl)
                Image(systemName: "xmark")
                    .font(.foySkipLabel)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }
        }
        .accessibilityLabel("Dismiss")
    }
}
