import SwiftUI

struct PaywallLegalFooterView: View {
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://mrdeakd.github.io/focusonyourself-docs/privacy.html")!

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("Subscription renews automatically unless cancelled 24 hours before the renewal date.")
                .font(.foyHint)
                .foregroundStyle(Color.foyPlaceholder)
                .multilineTextAlignment(.center)

            HStack(spacing: Spacing.xs) {
                Link("Terms of Use", destination: termsURL)
                    .font(.foyHint)
                    .foregroundStyle(Color.foyPlaceholder)

                Text("·")
                    .font(.foyHint)
                    .foregroundStyle(Color.foyPlaceholder)

                Link("Privacy Policy", destination: privacyURL)
                    .font(.foyHint)
                    .foregroundStyle(Color.foyPlaceholder)
            }
        }
    }
}
