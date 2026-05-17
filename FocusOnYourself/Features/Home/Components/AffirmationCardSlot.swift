import SwiftUI

struct AffirmationCardSlot: View {
    let index: Int
    let affirmations: [(quote: String, category: AffirmationCategory)]
    let isLoading: Bool

    var body: some View {
        if isLoading || index >= affirmations.count {
            AffirmationCardView(
                quote: "Generating your affirmation…",
                category: .confidence,
                isLoading: true
            )
            .shimmer()
        } else {
            AffirmationCardView(
                quote: affirmations[index].quote,
                category: affirmations[index].category,
                isLoading: false
            )
        }
    }
}
