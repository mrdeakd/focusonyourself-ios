import Factory
import Foundation

final class ArticlesService: ArticlesServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func dailyArticles() async throws -> [Article] {
        let path = "/api/articles/daily"
        let date = Date.now.formatted(.iso8601.year().month().day())
        do {
            let response: [Article] = try await networkClient.get("\(path)?date=\(date)")
            return response
        } catch {
            throw Self.mapDailyArticlesError(error)
        }
    }

    private static func mapDailyArticlesError(_ error: Error) -> ArticlesError { .fetchFailed }
}
