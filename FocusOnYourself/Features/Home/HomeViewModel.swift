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

    var sleepQuality: Int = 3
    var stressLevel: Int = 3
    var exercised = false
    var socialQuality: Int = 3

    @ObservationIgnored @Injected(\.checkInUseCase) private var checkInUseCase
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.affirmationUseCase) private var affirmationUseCase
    @ObservationIgnored @Injected(\.purchaseUseCase) private var purchaseUseCase
    @ObservationIgnored @Injected(\.articlesUseCase) private var articlesUseCase
    @ObservationIgnored @Injected(\.settingsUseCase) private var settingsUseCase
    @ObservationIgnored @Injected(\.healthKitUseCase) private var healthKitUseCase

    var articles: [Article] = []
    var isLoadingArticles = false
    var selectedArticle: Article?

    init() {
        isGeneratingAffirmation = true
    }

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

    func loadArticles() async {
        isLoadingArticles = true
        defer { isLoadingArticles = false }
        do {
            articles = try await articlesUseCase.dailyArticles()
        } catch {
            self.error = ErrorInfo(title: "Couldn't Load Articles")
        }
    }

    func selectMood(_ mood: Mood) {
        selectedMood = mood
    }

    func selectArticle(_ article: Article) {
        selectedArticle = article
    }

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
                await healthKitUseCase.save(mood: mood, factors: factors)
            }
        }
        showingContextSheet = false
    }

    func generateAffirmationIfNeeded() async {
        guard generatedQuotes.isEmpty else { return }
        isGeneratingAffirmation = true
        defer { isGeneratingAffirmation = false }
        do {
            let pairs = try await affirmationUseCase.generateBatch(
                count: 10,
                for: profileUseCase.selectedCategories,
                useAppleIntelligence: profileUseCase.isAppleIntelligenceActive && purchaseUseCase.isPro
            )
            generatedQuotes = pairs
        } catch {
            self.error = ErrorInfo(title: "Couldn't Load Affirmations")
        }
    }
}
