protocol AffirmationServiceProtocol {
    func fetchAffirmations(
        count: Int,
        for categories: [AffirmationCategory]
    ) async throws -> [CachedAffirmation]
}
