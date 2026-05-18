import Factory
import Foundation

final class MeditationUseCase: MeditationUseCaseProtocol {
    @Injected(\.meditationService) private var meditationService

    func sessions(for category: MeditationCategory?) async throws -> [MeditationSession] {
        try await meditationService.sessions(for: category)
    }
}
