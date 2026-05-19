import Factory
import Foundation

final class AffirmationService: AffirmationServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func fetchAffirmations(
        count: Int,
        for categories: [AffirmationCategory]
    ) async throws -> [CachedAffirmation] {
        let categoryParams = categories.map(\.rawValue).joined(separator: ",")
        return try await networkClient.get("/api/affirmations/batch?categories=\(categoryParams)&count=\(count)")
    }
}
