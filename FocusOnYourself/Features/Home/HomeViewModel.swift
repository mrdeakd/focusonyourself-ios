import Foundation
import Observation

@Observable
final class HomeViewModel {
    var selectedMood: Mood? = nil
    var hasCheckedIn: Bool = false
    var todaysMood: Mood? = nil
    var feelingsDescription: String = ""
    var isGeneratingAffirmation: Bool = false
    var generatedQuotes: [(quote: String, category: AffirmationCategory)] = []

    private let profileService: ProfileServiceProtocol
    private let affirmationService: AffirmationServiceProtocol

    private let quoteKey = "affirmation.quote"
    private let datKey  = "affirmation.date"

    private static let fallbackQuotes: [String] = [
        "I am worthy of love and respect exactly as I am.",
        "I choose to embrace each day with gratitude and purpose.",
        "I have the strength to overcome any challenge I face.",
        "I am growing into the best version of myself.",
        "I choose peace and let go of what I cannot control.",
        "I am deserving of good things and I welcome them.",
        "I have the power to create positive change in my life.",
        "I am enough, and I do enough.",
        "I choose kindness — to others and to myself.",
        "I am capable of achieving everything I set my mind to."
    ]

    init(
        profileService: ProfileServiceProtocol = ServiceContainer.shared.profileService,
        affirmationService: AffirmationServiceProtocol = ServiceContainer.shared.affirmationService
    ) {
        self.profileService = profileService
        self.affirmationService = affirmationService
        self.hasCheckedIn = profileService.hasCheckedInToday
        self.todaysMood = profileService.todaysMood
        loadCachedQuotes()
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

    var todayAffirmations: [(quote: String, category: AffirmationCategory)] {
        guard generatedQuotes.isEmpty else { return generatedQuotes }
        let categories = profileService.profile.selectedCategories
        let fallback: AffirmationCategory = .confidence
        return Self.fallbackQuotes.enumerated().map { index, quote in
            let category = categories.isEmpty ? fallback : categories[index % categories.count]
            return (quote: quote, category: category)
        }
    }

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

    // MARK: - Affirmations

    func generateAffirmationIfNeeded() async {
        guard profileService.profile.appleIntelligenceEnabled else { return }
        guard generatedQuotes.isEmpty else { return }

        isGeneratingAffirmation = true
        defer { isGeneratingAffirmation = false }

        let categories = profileService.profile.selectedCategories
        do {
            let pairs = try await affirmationService.generateBatch(count: 10, for: categories)
            generatedQuotes = pairs
            cacheQuotes(pairs)
        } catch {
            print("[HomeViewModel] Failed to generate affirmations: \(error)")
        }
    }

    private struct CachedAffirmation: Codable {
        let quote: String
        let category: AffirmationCategory
    }

    private func loadCachedQuotes() {
        let defaults = UserDefaults.standard
        let today = CheckIn.dateString(for: Date())
        guard defaults.string(forKey: datKey) == today,
              let data = defaults.data(forKey: quoteKey),
              let cached = try? JSONDecoder().decode([CachedAffirmation].self, from: data) else { return }
        generatedQuotes = cached.map { (quote: $0.quote, category: $0.category) }
    }

    private func cacheQuotes(_ pairs: [(quote: String, category: AffirmationCategory)]) {
        let defaults = UserDefaults.standard
        let cached = pairs.map { CachedAffirmation(quote: $0.quote, category: $0.category) }
        if let data = try? JSONEncoder().encode(cached) {
            defaults.set(data, forKey: quoteKey)
        }
        defaults.set(CheckIn.dateString(for: Date()), forKey: datKey)
    }
}
