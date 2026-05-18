import Foundation

protocol ArticlesUseCaseProtocol: AnyObject {
    func dailyArticles() async throws -> [Article]
}
