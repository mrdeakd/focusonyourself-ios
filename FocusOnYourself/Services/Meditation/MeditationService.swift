import Factory
import Foundation

final class MeditationService: MeditationServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func allSessions() async throws -> [MeditationSession] {
        let path = "/api/meditations"
        do {
            let response: [MeditationSession] = try await networkClient.get(path)
            return response
        } catch {
            throw Self.mapAllSessionsError(error)
        }
    }

    func sessions(in category: MeditationCategory) async throws -> [MeditationSession] {
        let path = "/api/meditations"
        let categoryParam = category.rawValue
        do {
            let response: [MeditationSession] = try await networkClient.get("\(path)?category=\(categoryParam)")
            return response
        } catch {
            throw Self.mapSessionsError(error)
        }
    }

    func narrationMap() async throws -> [String: String] {
        let path = "/api/narration-map"
        do {
            let response: [String: String] = try await networkClient.get(path)
            return response
        } catch {
            throw Self.mapNarrationMapError(error)
        }
    }

    private static func mapAllSessionsError(_ error: Error) -> MeditationError { .fetchFailed }
    private static func mapSessionsError(_ error: Error) -> MeditationError { .fetchFailed }
    private static func mapNarrationMapError(_ error: Error) -> MeditationError { .fetchFailed }
}
