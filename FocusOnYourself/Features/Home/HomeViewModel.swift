import Factory
import Foundation
import Observation

@Observable @MainActor
final class HomeViewModel {
    var selectedMood: Mood?
    var feelingsDescription: String = ""
    var showingContextSheet = false
    var isGeneratingAffirmation = false
    var generatedQuotes: [(quote: String, category: AffirmationCategory)] = []
    var error: ErrorInfo?

    var hasCheckedIn: Bool { profileService.hasCheckedInToday }
    var todaysMood: Mood? { profileService.todaysMood }
    var todaysFactors: CheckInFactors? { profileService.todaysFactors }
    var hasFactorsToday: Bool { profileService.todaysFactors != nil }

    var sleepQuality: Int = 3
    var stressLevel: Int = 3
    var exercised = false
    var socialQuality: Int = 3

    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.affirmationService) private var affirmationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService
    @ObservationIgnored @Injected(\.articlesService) private var articlesService
    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService

    var articles: [Article] = []
    var isLoadingArticles = false
    var selectedArticle: Article?

    init() {
        generatedQuotes = _affirmationService.wrappedValue.cachedBatch() ?? []
    }

    func loadArticles() async {
        isLoadingArticles = true
        defer { isLoadingArticles = false }
        do {
            articles = try await articlesService.dailyArticles()
        } catch {
            self.error = ErrorInfo(title: "Couldn't Load Articles")
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date.now)
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

    var formattedDate: String { Date.now.homeScreenFormatted }
    var streakCount: Int { profileService.streakStats().current }

    var showSleepFactor: Bool { userDefaultsService.getLocalBool(.showSleepFactor, defaultingTo: true) }
    var showStressFactor: Bool { userDefaultsService.getLocalBool(.showStressFactor, defaultingTo: true) }
    var showExerciseFactor: Bool { userDefaultsService.getLocalBool(.showExerciseFactor, defaultingTo: true) }
    var showSocialFactor: Bool { userDefaultsService.getLocalBool(.showSocialFactor, defaultingTo: true) }

    func selectMood(_ mood: Mood) {
        selectedMood = mood
    }

    func selectArticle(_ article: Article) {
        selectedArticle = article
    }

    func completeCheckIn() {
        guard let mood = selectedMood else { return }
        let description = feelingsDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        profileService.recordCheckIn(
            mood: mood,
            feelingsDescription: description.isEmpty ? nil : description,
            factors: nil
        )
    }

    func loadFactorsFromToday() {
        let existing = profileService.todaysFactors
        sleepQuality  = existing?.sleepQuality ?? 3
        stressLevel   = existing?.stressLevel ?? 3
        exercised     = existing?.exercised ?? false
        socialQuality = existing?.socialQuality ?? 3
    }

    func saveContext() {
        guard let mood = profileService.todaysMood else { return }
        let factors = CheckInFactors(
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            exercised: exercised,
            socialQuality: socialQuality
        )
        profileService.recordCheckIn(
            mood: mood,
            feelingsDescription: profileService.todaysFeelingsDescription,
            factors: factors
        )
        if #available(iOS 18, *) {
            Task { [weak self] in
                await self?.writeToHealthKit(mood: mood, factors: factors)
            }
        }
        showingContextSheet = false
    }

    @available(iOS 18, *)
    private func writeToHealthKit(mood: Mood, factors: CheckInFactors?) async {
        let service = Container.shared.healthKitService()
        await service.requestAuthorizationIfNeeded()
        service.writeStateOfMind(mood: mood, factors: factors)
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
            self.error = ErrorInfo(title: "Couldn't Load Affirmations")
        }
    }
}
