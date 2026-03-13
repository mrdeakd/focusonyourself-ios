import SwiftUI

struct AffirmationCardView: View {
    let quote: String
    let category: AffirmationCategory
    var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TODAY'S AFFIRMATION")
                .font(.foyMicroMedium)
                .foregroundStyle(Color.foyPlaceholder)
                .kerning(0.8)

            if isLoading {
                Text("Generating your affirmation…")
                    .font(.foyQuote)
                    .foregroundStyle(Color.foyPlaceholder)
                    .lineSpacing(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redacted(reason: .placeholder)
            } else {
                Text("\u{201C}\(quote)\u{201D}")
                    .font(.foyQuote)
                    .foregroundStyle(Color.foyForeground)
                    .lineSpacing(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("#\(category.rawValue)")
                .font(.foySectionLabel)
                .foregroundStyle(Color.foyNavy)
                .padding(.vertical, Spacing.xxxs)
                .padding(.horizontal, Spacing.sm)
                .background(Color.foyNavyTint)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.categoryTag))
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
    }
}
