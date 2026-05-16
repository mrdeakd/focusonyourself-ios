import SwiftUI

struct FOYToggle: View {
    @Binding var isOn: Bool

    private let trackWidth: CGFloat = 48
    private let trackHeight: CGFloat = 28
    private let thumbSize: CGFloat = 22
    private let thumbPadding: CGFloat = 3
    private let toggleCornerRadius: CGFloat = 14

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: toggleCornerRadius)
                    .fill(isOn ? Color.foyNavy : Color.foyButtonDisabled)
                    .frame(width: trackWidth, height: trackHeight)

                Circle()
                    .fill(Color.foyOnPrimary)
                    .frame(width: thumbSize, height: thumbSize)
                    .padding(thumbPadding)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            }
            .frame(width: trackWidth, height: trackHeight)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
