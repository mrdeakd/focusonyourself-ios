import SwiftUI

struct AffirmationDotIndicators: View {
    let itemCount: Int
    let currentIndex: Int

    private let activeDotWidth: CGFloat = 16
    private let dotHeight: CGFloat = 6
    private let inactiveDotSize: CGFloat = 6

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(0..<itemCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.foyNavy : Color.foyNavyTint)
                    .frame(
                        width: index == currentIndex ? activeDotWidth : inactiveDotSize,
                        height: dotHeight
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
    }
}
