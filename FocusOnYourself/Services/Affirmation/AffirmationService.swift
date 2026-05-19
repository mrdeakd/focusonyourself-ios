import Factory
import Foundation

final class AffirmationService: AffirmationServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func fetchAffirmations(
        count: Int,
        for categories: [AffirmationCategory]
    ) async throws -> [CachedAffirmation] {
        let path = "/api/affirmations/batch"
        let categoryParams = categories.map(\.rawValue).joined(separator: ",")
        let response: [CachedAffirmation] = try await networkClient.get(
            "\(path)?categories=\(categoryParams)&count=\(count)"
        )
        return response
    }
}
