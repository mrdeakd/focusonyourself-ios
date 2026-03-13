import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable {
    case welcome, name, categories, notifications
}

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var nameInput: String = ""
    var selectedCategories: [AffirmationCategory] = []
    private(set) var notificationsEnabled = false
    private(set) var isCompleted = false

    private let notificationService: NotificationServiceProtocol
    private let profileService: ProfileServiceProtocol

    init(
        notificationService: NotificationServiceProtocol = ServiceContainer.shared.notificationService,
        profileService: ProfileServiceProtocol = ServiceContainer.shared.profileService
    ) {
        self.notificationService = notificationService
        self.profileService = profileService
    }

    var isNameValid: Bool {
        !nameInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
