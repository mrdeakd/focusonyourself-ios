protocol StreaksServiceProtocol {
    func fetchMyStreaks(timezone: String) async throws -> StreakStatsResponse
}
