import SwiftUI

struct HomeArticlesSectionView: View {
    let articles: [Article]
    let onSelect: (Article) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("HEALTH & WELLNESS")

            ForEach(articles.prefix(4)) { article in
                Button {
                    onSelect(article)
                } label: {
                    ArticleCardView(article: article)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
