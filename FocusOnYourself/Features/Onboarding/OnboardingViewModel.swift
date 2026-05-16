import Factory
import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var nameInput: String = ""
    var selectedCategories: [AffirmationCategory] = []
    var showPaywall = false
    private(set) var notificationsEnabled = false
    private(set) var isCompleted = false

    @ObservationIgnored @Injected(\.notificationService) private var notificationService
    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService

    var isPro: Bool { purchaseService.isPro }

    var sortedCategories: [AffirmationCategory] {
        AffirmationCategory.allCases.sorted { $0.isFree && !$1.isFree }
    }

    var isNameValid: Bool {
        !nameInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
        let granted = await notificationService.requestPermission()
        notificationsEnabled = granted
        if granted {
            notificationService.schedule(name: nameInput)
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

    private func complete() {
        profileService.updateProfile(buildProfile())
        isCompleted = true
    }
}
