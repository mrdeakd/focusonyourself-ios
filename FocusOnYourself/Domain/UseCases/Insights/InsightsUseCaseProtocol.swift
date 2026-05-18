import Foundation

protocol InsightsUseCaseProtocol: AnyObject {
    func recentCheckIns(days: Int) -> [CheckIn]
    func checkInCount(days: Int) -> Int
    func averageMood(days: Int) -> Mood?
    func averageMoodText(days: Int) -> String
    func dailyMoodData(days: Int) -> [(label: String, checkIn: CheckIn?)]
    func weeklyAverages() -> [(week: String, avg: Double)]
    func monthlyAverages() -> [(month: String, avg: Double)]
    func moodDistribution(days: Int) -> [(mood: Mood, count: Int)]
    func factorCorrelations() -> [FactorCorrelation]
    func topMoodBooster() -> FactorCorrelation?
    func averageMood(forBinaryFactor keyPath: KeyPath<CheckInFactors, Bool>) -> (with: Double?, without: Double?)
    // swiftlint:disable:next line_length
    func averageMoodByRange(forFactor keyPath: KeyPath<CheckInFactors, Int>) -> (low: FactorRangeGroup, mid: FactorRangeGroup, high: FactorRangeGroup)
    func bestDayOfWeek(days: Int) -> String?
}
