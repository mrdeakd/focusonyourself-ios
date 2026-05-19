import Foundation

protocol ProfileUseCaseProtocol: AnyObject {
    var profile: UserProfile { get }

    var name: String { get }
    var selectedCategories: [AffirmationCategory] { get }
    var notificationsEnabled: Bool { get }
    var appearanceOverride: String? { get }
    var appleIntelligenceEnabled: Bool { get }
    var isAppleIntelligenceActive: Bool { get }
    var onboardingCompleted: Bool { get }

    func updateProfile(_ profile: UserProfile)
    func updateName(_ name: String)
    func updateCategories(_ categories: [AffirmationCategory])
    func updateNotificationsEnabled(_ enabled: Bool)
    func updateAppearanceOverride(_ override: String?)
    func updateAppleIntelligenceEnabled(_ enabled: Bool)
    func saveCompletedProfile(_ profile: UserProfile)
    func resetAll()
}
