import Factory
import Foundation
import FoundationModels
import HealthKit
import Observation

@Observable @MainActor
final class HomeViewModel {
    var selectedMood: Mood?
    var feelingsDescription: String = ""
    var showingContextSheet = false
    var isGeneratingAffirmation = false
    var generatedQuotes: [(quote: String, category: AffirmationCategory)] = []
    var error: ErrorInfo?

    var sleepQuality: Int = 3
    var stressLevel: Int = 3
    var exercised = false
    var socialQuality: Int = 3

    @ObservationIgnored @Injected(\.checkInUseCase) private var checkInUseCase
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.purchaseUseCase) private var purchaseUseCase
    @ObservationIgnored @Injected(\.settingsUseCase) private var settingsUseCase
    @ObservationIgnored @Injected(\.affirmationService) private var affirmationService
    @ObservationIgnored @Injected(\.articlesService) private var articlesService
    @ObservationIgnored @Injected(\.userDefaultsStore) private var userDefaultsStore

    private let distributionCalculator = DistributionCalculator()
    private let moodHealthKitCalculator = MoodHealthKitCalculator()
    private let dailyCacheChecker = DailyCacheChecker()
    private let healthStore = HKHealthStore()

    var articles: [Article] = []
    var isLoadingArticles = false
    var selectedArticle: Article?

    init() {
        isGeneratingAffirmation = true
    }

    // MARK: - Reactive reads

    var hasCheckedIn: Bool { checkInUseCase.hasCheckedInToday }
    var todaysMood: Mood? { checkInUseCase.todaysMood }
    var todaysFactors: CheckInFactors? { checkInUseCase.todaysFactors }
    var hasFactorsToday: Bool { todaysFactors != nil }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date.now)
        let timeOfDay: String
        switch hour {
        case 5..<12:  timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        default:      timeOfDay = "Good evening"
        }
        return profileUseCase.name.isEmpty ? timeOfDay : "\(timeOfDay), \(profileUseCase.name)"
    }

    var formattedDate: String { Date.now.homeScreenFormatted }
    var streakCount: Int { checkInUseCase.streakStats().current }

    var showSleepFactor: Bool { settingsUseCase.showSleepFactor }
    var showStressFactor: Bool { settingsUseCase.showStressFactor }
    var showExerciseFactor: Bool { settingsUseCase.showExerciseFactor }
    var showSocialFactor: Bool { settingsUseCase.showSocialFactor }

    // MARK: - Articles

    func loadArticles() async {
        isLoadingArticles = true
        defer { isLoadingArticles = false }
        do {
            articles = try await articlesService.dailyArticles()
        } catch {
            self.error = ErrorInfo(title: "Couldn't Load Articles")
        }
    }

    func selectMood(_ mood: Mood) { selectedMood = mood }
    func selectArticle(_ article: Article) { selectedArticle = article }

    // MARK: - Check-in

    func completeCheckIn() {
        guard let mood = selectedMood else { return }
        let description = feelingsDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await checkInUseCase.record(
                    mood: mood,
                    feelingsDescription: description.isEmpty ? nil : description,
                    factors: nil
                )
            } catch {
                self.error = ErrorInfo(title: "Check-in failed", description: "Please try again.")
            }
        }
    }

    func loadFactorsFromToday() {
        let existing = checkInUseCase.todaysFactors
        sleepQuality  = existing?.sleepQuality ?? 3
        stressLevel   = existing?.stressLevel ?? 3
        exercised     = existing?.exercised ?? false
        socialQuality = existing?.socialQuality ?? 3
    }

    func saveContext() {
        guard let mood = checkInUseCase.todaysMood else { return }
        let factors = CheckInFactors(
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            exercised: exercised,
            socialQuality: socialQuality
        )
        let feelingsDescription = checkInUseCase.todaysFeelingsDescription
        Task {
            do {
                try await checkInUseCase.record(mood: mood, feelingsDescription: feelingsDescription, factors: factors)
            } catch {
                self.error = ErrorInfo(title: "Check-in failed", description: "Please try again.")
            }
        }
        if #available(iOS 18, *) {
            Task { [weak self] in
                guard let self else { return }
                await writeMoodToHealthKit(mood: mood, factors: factors)
            }
        }
        showingContextSheet = false
    }

    // MARK: - Affirmation generation (inlined logic)

    func generateAffirmationIfNeeded() async {
        guard generatedQuotes.isEmpty else { return }
        isGeneratingAffirmation = true
        defer { isGeneratingAffirmation = false }

        if let cached = cachedAffirmations() {
            generatedQuotes = cached
            return
        }

        let categories = profileUseCase.selectedCategories
        guard !categories.isEmpty else { return }
        let useAppleIntelligence = profileUseCase.isAppleIntelligenceActive && purchaseUseCase.isPro

        do {
            let pairs: [(quote: String, category: AffirmationCategory)]
            if useAppleIntelligence {
                pairs = try await generateUsingAppleIntelligence(count: 10, for: categories)
            } else {
                let items = try await affirmationService.fetchAffirmations(count: 10, for: categories)
                pairs = items.map { (quote: $0.quote, category: $0.category) }
            }
            cacheAffirmations(pairs)
            generatedQuotes = pairs
        } catch {
            self.error = ErrorInfo(title: "Couldn't Load Affirmations")
        }
    }

    private func generateUsingAppleIntelligence(
        count: Int,
        for categories: [AffirmationCategory]
    ) async throws -> [(quote: String, category: AffirmationCategory)] {
        let counts = distributionCalculator.distribute(total: count, across: categories.count)
        var results: [(quote: String, category: AffirmationCategory)] = []
        for (category, affirmationCount) in zip(categories, counts) {
            let prompt = affirmationPrompt(category: category, count: affirmationCount)
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            let quotes = parseNumberedList(response.content, expected: affirmationCount)
            results += quotes.map { (quote: $0, category: category) }
        }
        return results
    }

    private func affirmationPrompt(category: AffirmationCategory, count: Int) -> String {
        """
        Write \(count) short, powerful daily affirmations in the theme of: \(category.displayName). \
        Use first person ("I am", "I have", or "I choose"). \
        Format as a numbered list (1. ... 2. ... etc.), one affirmation per line. \
        Return only the affirmation texts, no explanations.
        """
    }

    private func parseNumberedList(_ text: String, expected: Int) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var results: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let stripped = trimmed.replacing(#/^\d+\.\s*/#, with: "")
            if !stripped.isEmpty {
                results.append(stripped)
            }
        }
        return Array(results.prefix(expected))
    }

    // MARK: - Affirmation cache (inlined UserDefaults)

    private func cachedAffirmations() -> [(quote: String, category: AffirmationCategory)]? {
        let cachedDate = userDefaultsStore.string(for: .affirmationCacheDate)
        guard dailyCacheChecker.isFreshForToday(cachedDateString: cachedDate) else { return nil }
        guard let data = userDefaultsStore.data(for: .affirmationCache) else { return nil }
        guard let cached = try? JSONDecoder().decode([CachedAffirmation].self, from: data) else { return nil }
        return cached.map { (quote: $0.quote, category: $0.category) }
    }

    private func cacheAffirmations(_ pairs: [(quote: String, category: AffirmationCategory)]) {
        let cached = pairs.map { CachedAffirmation(quote: $0.quote, category: $0.category) }
        if let data = try? JSONEncoder().encode(cached) {
            userDefaultsStore.setData(data, for: .affirmationCache)
        }
        userDefaultsStore.setString(dailyCacheChecker.todayString(), for: .affirmationCacheDate)
    }

    // MARK: - HealthKit (inlined)

    @available(iOS 18, *)
    private func writeMoodToHealthKit(mood: Mood, factors: CheckInFactors?) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await healthStore.requestAuthorization(toShare: [HKObjectType.stateOfMindType()], read: [])
        } catch {
            return
        }
        let sample = HKStateOfMind(
            date: Date.now,
            kind: .dailyMood,
            valence: moodHealthKitCalculator.valence(for: mood),
            labels: moodHealthKitCalculator.labels(for: mood, factors: factors),
            associations: moodHealthKitCalculator.associations(for: factors)
        )
        try? await healthStore.save(sample)
    }
}
