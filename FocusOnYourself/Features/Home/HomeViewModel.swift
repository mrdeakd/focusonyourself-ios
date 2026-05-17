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

    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.affirmationService) private var affirmationService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService
    @ObservationIgnored @Injected(\.articlesService) private var articlesService
    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService

    var articles: [Article] = []
    var isLoadingArticles = false
    var selectedArticle: Article?

    init() {
        isGeneratingAffirmation = true
    }

    var hasCheckedIn: Bool {
        let dateString = CheckIn.dateString(for: Date.now)
        return profileService.profile.checkIns.contains { $0.dateString == dateString }
    }

    var todaysMood: Mood? {
        let dateString = CheckIn.dateString(for: Date.now)
        return profileService.profile.checkIns.first { $0.dateString == dateString }?.mood
    }

    var todaysFactors: CheckInFactors? {
        let dateString = CheckIn.dateString(for: Date.now)
        return profileService.profile.checkIns.first { $0.dateString == dateString }?.factors
    }

    var hasFactorsToday: Bool { todaysFactors != nil }

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

    var streakCount: Int {
        !profileService.profile.checkIns.isEmpty ? profileService.streakStats().current : 0
    }

    var showSleepFactor: Bool { userDefaultsService.getLocalBool(.showSleepFactor, defaultingTo: true) }
    var showStressFactor: Bool { userDefaultsService.getLocalBool(.showStressFactor, defaultingTo: true) }
    var showExerciseFactor: Bool { userDefaultsService.getLocalBool(.showExerciseFactor, defaultingTo: true) }
    var showSocialFactor: Bool { userDefaultsService.getLocalBool(.showSocialFactor, defaultingTo: true) }

    func loadArticles() async {
        isLoadingArticles = true
        defer { isLoadingArticles = false }
        do {
            articles = try await articlesService.dailyArticles()
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
        profileService.recordCheckIn(
            mood: mood,
            feelingsDescription: description.isEmpty ? nil : description,
            factors: nil
        )
    }

    func loadFactorsFromToday() {
        let dateString = CheckIn.dateString(for: Date.now)
        let existing = profileService.profile.checkIns.first { $0.dateString == dateString }?.factors
        sleepQuality  = existing?.sleepQuality ?? 3
        stressLevel   = existing?.stressLevel ?? 3
        exercised     = existing?.exercised ?? false
        socialQuality = existing?.socialQuality ?? 3
    }

    func saveContext() {
        let dateString = CheckIn.dateString(for: Date.now)
        guard let mood = profileService.profile.checkIns.first(where: { $0.dateString == dateString })?.mood else { return }
        let factors = CheckInFactors(
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            exercised: exercised,
            socialQuality: socialQuality
        )
        let feelingsDescription = profileService.profile.checkIns.first { $0.dateString == dateString }?.feelingsDescription
        profileService.recordCheckIn(
            mood: mood,
            feelingsDescription: feelingsDescription,
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
        await Container.shared.healthKitService().save(mood: mood, factors: factors)
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
        } catch {
            self.error = ErrorInfo(title: "Couldn't Load Affirmations")
        }
    }
}
