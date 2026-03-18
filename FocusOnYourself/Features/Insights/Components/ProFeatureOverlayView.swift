import SwiftUI

struct ProFeatureOverlayView<Content: View>: View {
    private let lockIconSize: CGFloat = 18

    let isLocked: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
                .blur(radius: isLocked ? 6 : 0)
                .allowsHitTesting(!isLocked)

            if isLocked {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(Font.foyMeditationTimer(size: lockIconSize))
                        .foregroundStyle(Color.foyNavy)
                    Text("Unlock trends with Pro")
                        .font(.foyBodyMedium)
                        .foregroundStyle(Color.foyForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }
        }
    }
}
