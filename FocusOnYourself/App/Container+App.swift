import Factory
import Foundation

extension Container {
    var userDefaultsService: Factory<UserDefaultsServiceProtocol> {
        self { @MainActor in UserDefaultsService() }.singleton
    }
    // Registered as concrete type: ProfileService is injected via SwiftUI .environment(),
    // which requires @Observable — protocols can't satisfy that constraint.
    var profileService: Factory<ProfileService> {
        self { @MainActor in ProfileService() }.singleton
    }
    var notificationService: Factory<NotificationServiceProtocol> {
        self { @MainActor in NotificationService() }.singleton
    }
    var affirmationService: Factory<AffirmationServiceProtocol> {
        self { @MainActor in AffirmationService() }.singleton
    }
    var purchaseService: Factory<PurchaseServiceProtocol> {
        self { @MainActor in PurchaseService() }.singleton
    }
    var keychainService: Factory<KeychainService> {
        self { @MainActor in KeychainService() }.singleton
    }
    var authService: Factory<AuthServiceProtocol> {
        self { @MainActor in AuthService() }.singleton
    }
    var networkClient: Factory<NetworkClientProtocol> {
        self { @MainActor in  URLSessionNetworkClient(keychain: self.keychainService()) }.singleton
    }
    var articlesService: Factory<ArticlesServiceProtocol> {
        self { @MainActor in  ArticlesService() }.singleton
    }
    var meditationService: Factory<MeditationServiceProtocol> {
        self { @MainActor in MeditationService() }.singleton
    }
    var meditationAudioService: Factory<MeditationAudioServiceProtocol> {
        self { @MainActor in MeditationAudioService() }.singleton
    }
    @available(iOS 18, *)
    var healthKitService: Factory<HealthKitServiceProtocol> {
        self { @MainActor in HealthKitService() }.singleton
    }
}
