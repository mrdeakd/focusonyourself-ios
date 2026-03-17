import SwiftUI

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            SheetDragHandle()
            VStack(alignment: .leading, spacing: Spacing.lg) {

                // Topic chip
                Text(article.topic.displayName.uppercased())
                    .font(.foyMicroMedium)
                    .foregroundStyle(article.topic.color)
                    .kerning(0.6)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(article.topic.tintColor)
                    .clipShape(Capsule())

                // Title
                Text(article.title)
                    .font(.foyNavTitle)
                    .foregroundStyle(Color.foyForeground)

                // Read time
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "clock")
                        .font(.system(size: 13))
                    Text("\(article.readTimeMinutes) min read")
                        .font(.foyCaption)
                }
                .foregroundStyle(Color.foyForegroundSecondary)

                Divider()

                // Body paragraphs
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(article.body.components(separatedBy: "\n\n"), id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.foyBody)
                            .foregroundStyle(Color.foyForeground)
                            .lineSpacing(8)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.screenBottom)
        }
        .scrollIndicators(.hidden)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
    }
}
