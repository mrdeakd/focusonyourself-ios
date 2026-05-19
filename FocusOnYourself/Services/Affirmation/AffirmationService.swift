import Factory
import Foundation

final class AffirmationService: AffirmationServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func fetchAffirmations(
        count: Int,
        for categories: [AffirmationCategory]
    ) async throws -> [(quote: String, category: AffirmationCategory)] {
        guard !categories.isEmpty else { return [] }
        let categoryParams = categories.map(\.rawValue).joined(separator: ",")
        let path = "/api/affirmations/batch?categories=\(categoryParams)&count=\(count)"
        let items: [CachedAffirmation] = try await networkClient.get(path)
        return items.map { (quote: $0.quote, category: $0.category) }
    }
}
