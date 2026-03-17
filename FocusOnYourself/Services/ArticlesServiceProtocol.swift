protocol ArticlesServiceProtocol {
    func allArticles() -> [Article]
    func articles(for topic: ArticleTopic?) -> [Article]
}
