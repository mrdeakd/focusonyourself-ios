import Foundation

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var selectedCategories: [AffirmationCategory] = []
    var notificationsEnabled = true
    var appleIntelligenceEnabled = false
    var onboardingCompleted = false
    var checkIns: [CheckIn] = []
    var appearanceOverride: String?
}
