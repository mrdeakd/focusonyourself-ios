import Factory
import Foundation

final class AffirmationUseCase: AffirmationUseCaseProtocol {
    @Injected(\.affirmationService) private var affirmationService

    func generateBatch(
        count: Int,
        for categories: [AffirmationCategory],
        useAppleIntelligence: Bool
    ) async throws -> [(quote: String, category: AffirmationCategory)] {
        try await affirmationService.generateBatch(
            count: count,
            for: categories,
            useAppleIntelligence: useAppleIntelligence
        )
    }
}
