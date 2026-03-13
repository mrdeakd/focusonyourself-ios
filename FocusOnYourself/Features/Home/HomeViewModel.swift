import Foundation
import Observation

@Observable
final class HomeViewModel {
    var selectedMood: Mood? = nil
    var hasCheckedIn: Bool = false
    var todaysMood: Mood? = nil
    var feelingsDescription: String = ""
    var isGeneratingAffirmation: Bool = false
    var generatedQuote: String? = nil

    private let profileService: ProfileServiceProtocol
    private let affirmationService: AffirmationServiceProtocol

    private let quoteKey = "affirmation.quote"
    private let datKey  = "affirmation.date"

    init(
        profileService: ProfileServiceProtocol = ServiceContainer.shared.profileService,
        affirmationService: AffirmationServiceProtocol = ServiceContainer.shared.affirmationService
    ) {
        self.profileService = profileService
        self.affirmationService = affirmationService
        self.hasCheckedIn = profileService.hasCheckedInToday
        self.todaysMood = profileService.todaysMood
        loadCachedQuote()
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

    var todayAffirmation: (quote: String, category: AffirmationCategory) {
        let category = profileService.profile.selectedCategories.first ?? .confidence
        let quote = generatedQuote ?? "I am worthy of love and respect exactly as I am."
        return (quote: quote, category: category)
    }

    func generateAffirmationIfNeeded() async {
        guard profileService.profile.appleIntelligenceEnabled else { return }
        guard generatedQuote == nil else { return }

        isGeneratingAffirmation = true
        defer { isGeneratingAffirmation = false }

        let categories = profileService.profile.selectedCategories
        do {
            let quote = try await affirmationService.generate(for: categories)
            generatedQuote = quote
            cacheQuote(quote)
        } catch {
            // Silent fallback — static quote remains
        }
    }

    func selectMood(_ mood: Mood) { selectedMood = mood }

    func completeCheckIn() {
        guard let mood = selectedMood else { return }
        let description = feelingsDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        profileService.recordCheckIn(mood: mood, feelingsDescription: description.isEmpty ? nil : description)
        hasCheckedIn = true
        todaysMood = mood
    }

    // MARK: - Private

    private func loadCachedQuote() {
        let defaults = UserDefaults.standard
        let today = CheckIn.dateString(for: Date())
        guard defaults.string(forKey: datKey) == today,
              let cached = defaults.string(forKey: quoteKey) else { return }
        generatedQuote = cached
    }

    private func cacheQuote(_ quote: String) {
        let defaults = UserDefaults.standard
        defaults.set(quote, forKey: quoteKey)
        defaults.set(CheckIn.dateString(for: Date()), forKey: datKey)
    }
}
