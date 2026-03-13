import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var draftName: String = ""
    var draftCategories: Set<AffirmationCategory> = []
    var draftNotifications: Bool = true
    var draftAppleIntelligence: Bool = false

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        loadDrafts()
    }

    func loadDrafts() {
        draftName = appState.profile.name
        draftCategories = Set(appState.profile.selectedCategories)
        draftNotifications = appState.profile.notificationsEnabled
        draftAppleIntelligence = appState.profile.appleIntelligenceEnabled
    }

    func save() {
        var updated = appState.profile
        updated.name = draftName
        updated.selectedCategories = AffirmationCategory.allCases.filter { draftCategories.contains($0) }
        updated.notificationsEnabled = draftNotifications
        updated.appleIntelligenceEnabled = draftAppleIntelligence
        appState.updateProfile(updated)
    }
}
