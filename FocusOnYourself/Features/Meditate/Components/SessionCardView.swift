import SwiftUI

struct SessionCardView: View {
    let session: MeditationSession
    let isPro: Bool

    private var isLocked: Bool { session.isPro && !isPro }

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
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, 2)
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
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isLocked ? Color.foyOrange : Color.foyPlaceholder)
        }
        .padding(Spacing.md)
        .foyCardStyle()
    }
}
