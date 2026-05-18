import Foundation

protocol AffirmationUseCaseProtocol: AnyObject {
    func generateBatch(
        count: Int,
        for categories: [AffirmationCategory],
        useAppleIntelligence: Bool
    ) async throws -> [(quote: String, category: AffirmationCategory)]
}
