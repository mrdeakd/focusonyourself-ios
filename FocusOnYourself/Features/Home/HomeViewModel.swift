import Foundation
import Observation

@Observable @MainActor
final class HomeViewModel {
    var selectedMood: Mood? = nil
    var hasCheckedIn: Bool = false
    var todaysMood: Mood? = nil
    var feelingsDescription: String = ""
    var isGeneratingAffirmation: Bool = false
    var generatedQuotes: [(quote: String, category: AffirmationCategory)] = []
    var errorMessage: String?

    private let profileService: ProfileServiceProtocol
    private let affirmationService: AffirmationServiceProtocol
    private let purchaseService: PurchaseServiceProtocol

    init(
        profileService: ProfileServiceProtocol = ServiceContainer.shared.profileService,
        affirmationService: AffirmationServiceProtocol = ServiceContainer.shared.affirmationService,
        purchaseService: PurchaseServiceProtocol = ServiceContainer.shared.purchaseService
    ) {
        self.profileService = profileService
        self.affirmationService = affirmationService
        self.purchaseService = purchaseService
        self.hasCheckedIn = profileService.hasCheckedInToday
        self.todaysMood = profileService.todaysMood
        generatedQuotes = affirmationService.cachedBatch() ?? []
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
