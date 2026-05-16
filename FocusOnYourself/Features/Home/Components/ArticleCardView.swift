import SwiftUI

struct ArticleCardView: View {
    let article: Article

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconBox(
                systemName: article.topic.icon,
                tintColor: article.topic.tintColor,
                iconColor: article.topic.color,
                iconSize: 18
            )

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(article.topic.displayName.uppercased())
                    .font(.foyMicroMedium)
                    .foregroundStyle(article.topic.color)
                    .kerning(0.6)

                Text(article.title)
                    .font(.foyBodyMedium)
                    .foregroundStyle(Color.foyForeground)
                    .lineLimit(2)

                Text("\(article.readTimeMinutes) min read")
                    .font(.foyCaption)
                    .foregroundStyle(Color.foyForegroundSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.foyCaptionMedium)
                .foregroundStyle(Color.foyPlaceholder)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .foyCardStyle()
    }
}
