import Foundation

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var selectedCategories: [AffirmationCategory] = []
    var notificationsEnabled: Bool = true
    var appleIntelligenceEnabled: Bool = false
    var onboardingCompleted: Bool = false
    var checkIns: [CheckIn] = []
    var appearanceOverride: String?
    var preferredLanguage: String?
}
