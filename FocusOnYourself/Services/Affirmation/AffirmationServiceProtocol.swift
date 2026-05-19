protocol AffirmationServiceProtocol {
    func fetchAffirmations(
        count: Int,
        for categories: [AffirmationCategory]
    ) async throws -> [(quote: String, category: AffirmationCategory)]
}
