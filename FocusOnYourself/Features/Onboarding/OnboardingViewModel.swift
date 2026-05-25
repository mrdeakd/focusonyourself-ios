import Factory
import Foundation
import Observation

@Observable @MainActor
final class OnboardingViewModel {
    @ObservationIgnored @Injected(\.notificationsUseCase) private var notificationsUseCase
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.purchaseUseCase) private var purchaseUseCase

    // MARK: - State

    var currentStep: OnboardingStep = .welcome
    var nameInput: String = ""
    var selectedCategories: [AffirmationCategory] = []
    var showPaywall = false
    private(set) var notificationsEnabled = false
    private(set) var isCompleted = false

    // MARK: - Computed

    var isPro: Bool { purchaseUseCase.isPro }

    var sortedCategories: [AffirmationCategory] {
        AffirmationCategory.allCases.sorted { $0.isFree && !$1.isFree }
    }

    var isNameValid: Bool {
        !nameInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Public methods

    func requestUnlock() { showPaywall = true }

    func advance() {
        let all = OnboardingStep.allCases
        guard let idx = all.firstIndex(of: currentStep), idx + 1 < all.count else { return }
        currentStep = all[idx + 1]
    }

    func toggleCategory(_ category: AffirmationCategory) {
        if let idx = selectedCategories.firstIndex(of: category) {
            selectedCategories.remove(at: idx)
        } else {
            selectedCategories.append(category)
        }
    }

    func enableNotifications() async {
        let granted = await notificationsUseCase.requestPermission()
        notificationsEnabled = granted
        if granted {
            notificationsUseCase.schedule(name: nameInput)
        }
        complete()
    }

    func skipNotifications() {
        notificationsEnabled = false
        complete()
    }

    func buildProfile() -> UserProfile {
        UserProfile(
            name: nameInput.trimmingCharacters(in: .whitespaces),
            selectedCategories: selectedCategories,
            notificationsEnabled: notificationsEnabled,
            appleIntelligenceEnabled: false,
            onboardingCompleted: true
        )
    }

    // MARK: - Private methods

    private func complete() {
        profileUseCase.saveCompletedProfile(buildProfile())
        isCompleted = true
    }
}
