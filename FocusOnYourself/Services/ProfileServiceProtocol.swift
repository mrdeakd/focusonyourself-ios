import Foundation

protocol ProfileServiceProtocol: AnyObject {
    var profile: UserProfile { get }

    func updateProfile(_ profile: UserProfile)
    func recordCheckIn(mood: Mood, feelingsDescription: String?, factors: CheckInFactors?)
    func streakStats() -> (current: Int, longest: Int)
    func profileUpdates() -> AsyncStream<UserProfile>

    var streakStartDate: Date? { get }
    var earliestCheckInDate: Date? { get }
    var hasCheckedInToday: Bool { get }
    var todaysMood: Mood? { get }
    var todaysFeelingsDescription: String? { get }
    var todaysFactors: CheckInFactors? { get }

    func resetAllData()
    func mergeWidgetCheckIn()
    func replaceCheckIns(_ checkIns: [CheckIn])
}
