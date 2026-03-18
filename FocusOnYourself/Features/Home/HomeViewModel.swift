import Factory
import Foundation
import Observation

@Observable @MainActor
final class HomeViewModel {
    var selectedMood: Mood?
    var hasCheckedIn: Bool = false
    var todaysMood: Mood?
    var feelingsDescription: String = ""
    var isGeneratingAffirmation: Bool = false
    var generatedQuotes: [(quote: String, category: AffirmationCategory)] = []
    var errorMessage: String?

    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.affirmationService) private var affirmationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService
    @ObservationIgnored @Injected(\.articlesService) private var articlesService

    var articles: [Article] { articlesService.dailyArticles() }

    init() {
        hasCheckedIn = _profileService.wrappedValue.hasCheckedInToday
        todaysMood = _profileService.wrappedValue.todaysMood
        generatedQuotes = _affirmationService.wrappedValue.cachedBatch() ?? []
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12:  timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        default:      timeOfDay = "Good evening"
        }
        return profileService.profile.name.isEmpty
            ? timeOfDay
            : "\(timeOfDay), \(profileService.profile.name)"
    }

    var formattedDate: String { Date().homeScreenFormatted }

    var streakCount: Int { profileService.streakStats().current }

    func selectMood(_ mood: Mood) {
        selectedMood = mood
    }

    func completeCheckIn() {
        guard let mood = selectedMood else { return }
        let description = feelingsDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        profileService.recordCheckIn(mood: mood, feelingsDescription: description.isEmpty ? nil : description)
        hasCheckedIn = true
        todaysMood = mood
    }

    func generateAffirmationIfNeeded() async {
        guard generatedQuotes.isEmpty else { return }

        isGeneratingAffirmation = true
        defer { isGeneratingAffirmation = false }

        do {
            let pairs = try await affirmationService.generateBatch(
                count: 10,
                for: profileService.profile.selectedCategories,
                useAppleIntelligence: profileService.profile.isAppleIntelligenceActive && purchaseService.isPro
            )
            generatedQuotes = pairs
            affirmationService.cacheBatch(pairs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
