import Foundation
import Observation

@Observable
final class HomeViewModel {
    var selectedMood: Mood? = nil
    var hasCheckedIn: Bool = false

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12:  timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        default:      timeOfDay = "Good evening"
        }
        return appState.profile.name.isEmpty ? timeOfDay : "\(timeOfDay), \(appState.profile.name)"
    }

    var formattedDate: String {
        Date().homeScreenFormatted
    }

    var streakCount: Int { appState.streakStats().current }

    var todayAffirmation: (quote: String, category: AffirmationCategory) {
        // Placeholder affirmation — rotated daily in a future iteration
        let category = appState.profile.selectedCategories.first ?? .confidence
        return (quote: "I am worthy of love and respect exactly as I am.", category: category)
    }

    func selectMood(_ mood: Mood) {
        selectedMood = mood
    }

    func completeCheckIn() {
        guard let mood = selectedMood else { return }
        appState.recordCheckIn(mood: mood)
        hasCheckedIn = true
    }
}
