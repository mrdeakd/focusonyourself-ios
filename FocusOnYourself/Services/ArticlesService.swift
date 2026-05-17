import Factory
import Foundation

final class ArticlesService: ArticlesServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func dailyArticles() async throws -> [Article] {
        try await networkClient.get("/api/articles/daily?date=\(Date.now.formatted(.iso8601.year().month().day()))")
    }
}
