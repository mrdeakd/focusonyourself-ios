import Factory
import Foundation

extension Container {
    var userDefaultsService: Factory<UserDefaultsServiceProtocol> {
        self { @MainActor in UserDefaultsService() }.singleton
    }
    var profileService: Factory<ProfileService> {
        self { @MainActor in ProfileService(userDefaultsService: self.userDefaultsService()) }.singleton
    }
    var notificationService: Factory<NotificationServiceProtocol> {
        self { @MainActor in NotificationService() }.singleton
    }
    var affirmationService: Factory<AffirmationServiceProtocol> {
        self { @MainActor in AffirmationService(networkClient: self.networkClient()) }.singleton
    }
    var purchaseService: Factory<PurchaseServiceProtocol> {
        self { @MainActor in PurchaseService(userDefaultsService: self.userDefaultsService()) }.singleton
    }
    var keychainService: Factory<KeychainService> {
        self { KeychainService() }.singleton
    }
    var authService: Factory<AuthServiceProtocol> {
        self { @MainActor in AuthService(keychain: self.keychainService(), networkClient: self.networkClient()) }.singleton
    }
    var networkClient: Factory<NetworkClientProtocol> {
        self { URLSessionNetworkClient(keychain: self.keychainService()) }.singleton
    }
    var articlesService: Factory<ArticlesServiceProtocol> {
        self { ArticlesService(networkClient: self.networkClient()) }.singleton
    }
    var meditationService: Factory<MeditationServiceProtocol> {
        self { MeditationService(networkClient: self.networkClient()) }.singleton
    }
    var meditationAudioService: Factory<MeditationAudioService> {
        self { @MainActor in MeditationAudioService(networkClient: self.networkClient()) }.singleton
    }
    @available(iOS 18, *)
    var healthKitService: Factory<HealthKitService> {
        self { @MainActor in HealthKitService() }.singleton
    }
}
