import Foundation

protocol CheckInUseCaseProtocol: AnyObject {
    func record(mood: Mood, feelingsDescription: String?, factors: CheckInFactors?) async throws
    func replaceAll(_ checkIns: [CheckIn]) async throws
    func mergeWidgetCheckIn()
    func reset()

    var hasCheckedInToday: Bool { get }
    var todaysMood: Mood? { get }
    var todaysFeelingsDescription: String? { get }
    var todaysFactors: CheckInFactors? { get }
    var earliestCheckInDate: Date? { get }
    var allCheckIns: [CheckIn] { get }

    func streakStats() -> (current: Int, longest: Int)
    func streakStartDate() -> Date?
    func checkIn(for dateString: String) -> CheckIn?
}
