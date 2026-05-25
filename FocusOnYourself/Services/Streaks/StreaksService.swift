import Factory
import Foundation

final class StreaksService: StreaksServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func fetchMyStreaks(timezone: String) async throws -> StreakStatsResponse {
        let encoded = timezone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? timezone
        let path = "/api/streaks/me?tz=\(encoded)"
        do {
            let response: StreakStatsResponse = try await networkClient.get(path)
            return response
        } catch {
            throw Self.mapFetchError(error)
        }
    }

    private static func mapFetchError(_ error: Error) -> StreaksError {
        switch (error as? NetworkError)?.statusCode {
        case 401: .unauthorized
        default:  .fetchFailed
        }
    }
}
