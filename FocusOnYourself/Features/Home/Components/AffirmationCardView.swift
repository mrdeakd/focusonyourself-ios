import SwiftUI

struct AffirmationCardView: View {
    let quote: String
    let category: AffirmationCategory

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TODAY'S AFFIRMATION")
                .font(.inter(10, weight: .medium))
                .foregroundStyle(Color.foyPlaceholder)
                .kerning(0.8)

            Text(""\(quote)"")
                .font(.inter(18, weight: .light))
                .foregroundStyle(Color.foyForeground)
                .lineSpacing(9)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("#\(category.rawValue)")
                .font(.inter(11, weight: .medium))
                .foregroundStyle(Color.foyNavy)
                .padding(.vertical, Spacing.xxxs)
                .padding(.horizontal, 10)
                .background(Color.foyNavyTint)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.categoryTag))
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.foyCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
    }
}
