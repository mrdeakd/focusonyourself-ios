import Factory
import Foundation

final class AffirmationService: AffirmationServiceProtocol {
    @Injected(\.networkClient) private var networkClient
    @Injected(\.userDefaultsService) private var userDefaultsService
    @Injected(\.appleIntelligenceService) private var appleIntelligenceService

    func generateBatch(
        count: Int,
        for categories: [AffirmationCategory],
        useAppleIntelligence: Bool
    ) async throws -> [(quote: String, category: AffirmationCategory)] {
        guard !categories.isEmpty else { return [] }

        if let cached = cachedBatch() {
            return cached
        }

        let result: [(quote: String, category: AffirmationCategory)]

        if useAppleIntelligence {
            result = try await appleIntelligenceService.generateAffirmations(count: count, for: categories)
        } else {
            let categoryParams = categories.map(\.rawValue).joined(separator: ",")
            let path = "/api/affirmations/batch?categories=\(categoryParams)&count=\(count)"
            let items: [CachedAffirmation] = try await networkClient.get(path)
            result = items.map { (quote: $0.quote, category: $0.category) }
        }

        cacheBatch(result)
        return result
    }
}

// MARK: - Cache
extension AffirmationService {
    private func cachedBatch() -> [(quote: String, category: AffirmationCategory)]? {
        let today = CheckIn.dateString(for: Date.now)
        guard userDefaultsService.getString(.affirmationCacheDate) == today,
            let data = userDefaultsService.getData(.affirmationCache),
            let cached = try? JSONDecoder().decode([CachedAffirmation].self, from: data)
        else { return nil }
        return cached.map { (quote: $0.quote, category: $0.category) }
    }

    private func cacheBatch(_ pairs: [(quote: String, category: AffirmationCategory)]) {
        let cached = pairs.map { CachedAffirmation(quote: $0.quote, category: $0.category) }
        if let data = try? JSONEncoder().encode(cached) {
            userDefaultsService.setData(.affirmationCache, value: data)
        }
        userDefaultsService.setString(.affirmationCacheDate, value: CheckIn.dateString(for: Date.now))
    }
}
