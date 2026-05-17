protocol AppleIntelligenceServiceProtocol {
    func generateAffirmations(
        count: Int,
        for categories: [AffirmationCategory]
    ) async throws -> [(quote: String, category: AffirmationCategory)]
}
