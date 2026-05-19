import Factory
import Foundation

final class MeditationService: MeditationServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func allSessions() async throws -> [MeditationSession] {
        let path = "/api/meditations"
        let response: [MeditationSession] = try await networkClient.get(path)
        return response
    }

    func sessions(in category: MeditationCategory) async throws -> [MeditationSession] {
        let path = "/api/meditations"
        let categoryParam = category.rawValue
        let response: [MeditationSession] = try await networkClient.get("\(path)?category=\(categoryParam)")
        return response
    }
}
