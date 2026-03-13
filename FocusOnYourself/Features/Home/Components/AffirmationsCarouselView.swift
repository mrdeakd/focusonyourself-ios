import SwiftUI

struct AffirmationsCarouselView: View {
    let affirmations: [(quote: String, category: AffirmationCategory)]
    var isLoading: Bool = false

    @State private var scrollPosition: Int? = 0

    private let cardWidth: CGFloat = 240
    private let activeDotWidth: CGFloat = 16
    private let dotHeight: CGFloat = 6
    private let inactiveDotSize: CGFloat = 6
    private let dotSpacing: CGFloat = 6

    private var currentIndex: Int { scrollPosition ?? 0 }
    private var itemCount: Int { isLoading ? 10 : affirmations.count }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text("TODAY'S AFFIRMATIONS")
                .font(.foyMicroMedium)
                .foregroundStyle(Color.foyPlaceholder)
                .kerning(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<itemCount, id: \.self) { index in
                        cardView(at: index)
                            .frame(width: cardWidth)
                            .frame(maxHeight: .infinity)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                                    .opacity(phase.isIdentity ? 1.0 : 0.75)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .fixedSize(horizontal: false, vertical: true)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, Spacing.xl, for: .scrollContent)
            .scrollPosition(id: $scrollPosition)

            dotIndicators
        }
    }

    @ViewBuilder
    private func cardView(at index: Int) -> some View {
        if isLoading || index >= affirmations.count {
            AffirmationCardView(
                quote: "Generating your affirmation…",
                category: .confidence,
                isLoading: true
            )
        } else {
            AffirmationCardView(
                quote: affirmations[index].quote,
                category: affirmations[index].category,
                isLoading: false
            )
        }
    }

    private var dotIndicators: some View {
        HStack(spacing: dotSpacing) {
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
