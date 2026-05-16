import Foundation

final class ArticlesService: ArticlesServiceProtocol {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func dailyArticles() async throws -> [Article] {
        try await networkClient.get("/api/articles/daily?date=\(Date.now.formatted(.iso8601.year().month().day()))")
    }
}
