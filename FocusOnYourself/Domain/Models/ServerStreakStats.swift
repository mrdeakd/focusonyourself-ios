struct ServerStreakStats: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let streakStartDate: String?
    let lastCheckInDate: String?
}
