import SwiftUI

struct AffirmationCardView: View {
    let quote: String
    let category: AffirmationCategory

    private let quoteFont = Font.custom("Inter", size: 18).weight(.light)
    private let affirmationLabelFont = Font.custom("Inter", size: 10).weight(.medium)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TODAY'S AFFIRMATION")
                .font(affirmationLabelFont)
                .foregroundStyle(Color.foyPlaceholder)
                .kerning(0.8)

            Text("\u{201C}\(quote)\u{201D}")
                .font(quoteFont)
                .foregroundStyle(Color.foyForeground)
                .lineSpacing(9)
                .frame(maxWidth: .infinity, alignment: .leading)

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
