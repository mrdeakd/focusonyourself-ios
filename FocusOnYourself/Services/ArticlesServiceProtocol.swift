protocol ArticlesServiceProtocol {
    func allArticles() -> [Article]
    func dailyArticles() -> [Article]
    func articles(for topic: ArticleTopic?) -> [Article]
}
