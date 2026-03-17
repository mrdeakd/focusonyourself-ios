import SwiftUI

struct FoyPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.foyButtonLabel)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.buttonVertical)
            .background(isEnabled ? Color.foyNavy : Color.foyButtonDisabled)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}
