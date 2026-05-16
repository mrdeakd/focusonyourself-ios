import SwiftUI

struct AffirmationsCarouselView: View {
    let affirmations: [(quote: String, category: AffirmationCategory)]
    var isLoading = false

    @State private var scrollPosition: Int? = 0

    private let cardWidth: CGFloat = 240

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

            ScrollView(.horizontal) {
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<itemCount, id: \.self) { index in
                        AffirmationCardSlot(index: index, affirmations: affirmations, isLoading: isLoading)
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
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, Spacing.xl, for: .scrollContent)
            .scrollPosition(id: $scrollPosition)

            AffirmationDotIndicators(itemCount: itemCount, currentIndex: currentIndex)
        }
    }
}
