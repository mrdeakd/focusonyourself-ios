protocol ArticlesServiceProtocol {
    func dailyArticles() async throws -> [Article]
}
