import SwiftUI

struct PaywallTitleSection: View {
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("Unlock FocusOnYourself Pro")
                .font(.foyHeadline)
                .kerning(-0.3)
                .foregroundStyle(Color.foyForeground)
                .multilineTextAlignment(.center)

            Text("Everything you need for daily growth")
                .font(.foyCaption)
                .foregroundStyle(Color.foyForegroundSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
