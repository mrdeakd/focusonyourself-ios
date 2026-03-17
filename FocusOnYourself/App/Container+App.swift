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
        self { @MainActor in AffirmationService(userDefaultsService: self.userDefaultsService()) }.singleton
    }
    var purchaseService: Factory<PurchaseServiceProtocol> {
        self { @MainActor in PurchaseService(userDefaultsService: self.userDefaultsService()) }.singleton
    }
    var articlesService: Factory<ArticlesServiceProtocol> {
        self { ArticlesService() }.singleton
    }
    var meditationService: Factory<MeditationServiceProtocol> {
        self { MeditationService() }.singleton
    }
}
