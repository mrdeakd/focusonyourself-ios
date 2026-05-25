import Foundation

protocol CheckInUseCaseProtocol: AnyObject {
    var hasCheckedInToday: Bool { get }
    var todaysMood: Mood? { get }
    var todaysFeelingsDescription: String? { get }
    var todaysFactors: CheckInFactors? { get }
    var earliestCheckInDate: Date? { get }
    var allCheckIns: [CheckIn] { get }
    var serverStreaks: ServerStreakStats? { get }

    func record(mood: Mood, feelingsDescription: String?, factors: CheckInFactors?) async throws
    func replaceAll(_ checkIns: [CheckIn]) async throws
    func mergeWidgetCheckIn()
    func reset()

    func uploadAllToServer() async throws
    func downloadAndReplaceFromServer() async throws
    func refreshStreaksFromServer() async throws

    func streakStats() -> (current: Int, longest: Int)
    func checkIn(for dateString: String) -> CheckIn?
}
