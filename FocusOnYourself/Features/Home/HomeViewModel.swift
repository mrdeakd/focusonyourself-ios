import Foundation
import Observation

@Observable
final class HomeViewModel {
    var selectedMood: Mood? = nil
    var hasCheckedIn: Bool = false

    private let profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12:  timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        default:      timeOfDay = "Good evening"
        }
        return profile.name.isEmpty ? timeOfDay : "\(timeOfDay), \(profile.name)"
    }

    var formattedDate: String {
        Date().homeScreenFormatted
    }

    // Placeholder — streak tracking not yet implemented
    var streakCount: Int { 12 }

    var todayAffirmation: (quote: String, category: AffirmationCategory) {
        // Placeholder affirmation — rotated daily in a future iteration
        let category = profile.selectedCategories.first ?? .confidence
        return (quote: "I am worthy of love and respect exactly as I am.", category: category)
    }

    func selectMood(_ mood: Mood) {
        selectedMood = mood
    }

    func completeCheckIn() {
        guard selectedMood != nil else { return }
        hasCheckedIn = true
    }
}
