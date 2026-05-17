import SwiftUI

struct SkeletonAccountCard: View {
    @State private var shimmerPhase: CGFloat = -1

    private let cardRadius: CGFloat = 20
    private let avatarSize: CGFloat = 52
    private let lineRadius: CGFloat = 4

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(shimmerGradient)
                .frame(width: avatarSize, height: avatarSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: lineRadius)
                    .fill(shimmerGradient)
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)

                RoundedRectangle(cornerRadius: lineRadius)
                    .fill(shimmerGradient)
                    .frame(height: 11)
                    .frame(maxWidth: 120)
            }

            Spacer()

            Capsule()
                .fill(shimmerGradient)
                .frame(width: 40, height: 22)
        }
        .padding(Spacing.md)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.foyPlaceholder.opacity(0.5), location: shimmerPhase - 0.3),
                .init(color: Color.foyPlaceholder.opacity(0.15), location: shimmerPhase),
                .init(color: Color.foyPlaceholder.opacity(0.5), location: shimmerPhase + 0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
