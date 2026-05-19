import Factory
import Foundation

final class MeditationService: MeditationServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func allSessions() async throws -> [MeditationSession] {
        try await networkClient.get("/api/meditations")
    }

    func sessions(in category: MeditationCategory) async throws -> [MeditationSession] {
        try await networkClient.get("/api/meditations?category=\(category.rawValue)")
    }
}
