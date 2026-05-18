import Factory
import Foundation

final class ArticlesUseCase: ArticlesUseCaseProtocol {
    @Injected(\.articlesService) private var articlesService

    func dailyArticles() async throws -> [Article] {
        try await articlesService.dailyArticles()
    }
}
