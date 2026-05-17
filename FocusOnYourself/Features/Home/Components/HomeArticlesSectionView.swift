import SwiftUI

struct HomeArticlesSectionView: View {
    let articles: [Article]
    let onSelect: (Article) -> Void
    var isLoading = false

    var body: some View {
        if isLoading || !articles.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionLabel("HEALTH & WELLNESS")

                if isLoading {
                    ForEach(0..<4, id: \.self) { _ in
                        ArticleCardView(article: .placeholder)
                            .redacted(reason: .placeholder)
                            .shimmer()
                    }
                } else {
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
    }
}
