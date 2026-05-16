import SwiftUI

struct SessionCardView: View {
    let session: MeditationSession
    let isPro: Bool

    private var isLocked: Bool { session.isPro && !isPro }
    private let proBadgePaddingV: CGFloat = 2

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconBox(
                systemName: session.category.icon,
                tintColor: Color.foyNavyTint,
                iconColor: Color.foyNavy
            )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack(spacing: Spacing.xxs) {
                    Text(session.category.displayName.uppercased())
                        .font(.foyMicroMedium)
                        .foregroundStyle(Color.foyPlaceholder)
                        .kerning(0.6)

                    if session.isPro {
                        Text("PRO")
                            .font(.foyMicroMedium)
                            .foregroundStyle(Color.foyOnPrimary)
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, proBadgePaddingV)
                            .background(Color.foyOrange)
                            .clipShape(Capsule())
                    }
                }

                Text(session.title)
                    .font(.foyBodyMedium)
                    .foregroundStyle(Color.foyForeground)

                Text("\(session.durationMinutes) min")
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }

            Spacer()

            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .font(.foyCaptionMedium)
                .foregroundStyle(isLocked ? Color.foyOrange : Color.foyPlaceholder)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .foyCardStyle()
    }
}
