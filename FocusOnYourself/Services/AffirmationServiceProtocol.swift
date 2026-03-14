import Foundation

protocol AffirmationServiceProtocol {
    func generateBatch(count: Int, for categories: [AffirmationCategory], useAppleIntelligence: Bool) async throws -> [(quote: String, category: AffirmationCategory)]
}
