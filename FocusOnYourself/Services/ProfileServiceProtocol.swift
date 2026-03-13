import Foundation

protocol ProfileServiceProtocol: AnyObject {
    var profile: UserProfile { get }
    func updateProfile(_ profile: UserProfile)
    func recordCheckIn(mood: Mood, feelingsDescription: String?)
    func streakStats() -> (current: Int, longest: Int)
    var streakStartDate: Date? { get }
    var hasCheckedInToday: Bool { get }
    var todaysMood: Mood? { get }
    var todaysFeelingsDescription: String? { get }
}
