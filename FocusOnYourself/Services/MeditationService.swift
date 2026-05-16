import Foundation

final class MeditationService: MeditationServiceProtocol {
    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func sessions(for category: MeditationCategory?) async throws -> [MeditationSession] {
        let path = category.map { "/api/meditations?category=\($0.rawValue)" } ?? "/api/meditations"
        return try await networkClient.get(path)
    }
}
