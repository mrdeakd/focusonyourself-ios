import Factory
import Foundation

extension Container {
    // MARK: - Services (network only)

    var networkClient: Factory<NetworkClientProtocol> {
        self { @MainActor in URLSessionNetworkClient() }.singleton
    }
    var checkinsService: Factory<CheckinsServiceProtocol> {
        self { CheckinsService() }.singleton
    }
    var articlesService: Factory<ArticlesServiceProtocol> {
        self { @MainActor in ArticlesService() }.singleton
    }
    var meditationService: Factory<MeditationServiceProtocol> {
        self { @MainActor in MeditationService() }.singleton
    }
    var affirmationService: Factory<AffirmationServiceProtocol> {
        self { @MainActor in AffirmationService() }.singleton
    }

    // MARK: - Use Cases

    var profileUseCase: Factory<ProfileUseCaseProtocol> {
        self { @MainActor in ProfileUseCase() }.singleton
    }
    var purchaseUseCase: Factory<PurchaseUseCaseProtocol> {
        self { @MainActor in PurchaseUseCase() }.singleton
    }
    var authUseCase: Factory<AuthUseCaseProtocol> {
        self { @MainActor in AuthUseCase() }.singleton
    }
    var checkInUseCase: Factory<CheckInUseCaseProtocol> {
        self { @MainActor in CheckInUseCase() }.singleton
    }
    var notificationsUseCase: Factory<NotificationsUseCaseProtocol> {
        self { @MainActor in NotificationsUseCase() }.singleton
    }
    var settingsUseCase: Factory<SettingsUseCaseProtocol> {
        self { @MainActor in SettingsUseCase() }.singleton
    }
}
