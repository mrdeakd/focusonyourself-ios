import Foundation

@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    let userDefaultsService: UserDefaultsServiceProtocol
    let profileService: ProfileService
    let notificationService: NotificationService
    let affirmationService: AffirmationServiceProtocol
    let purchaseService: PurchaseService

    private init() {
        let uds = UserDefaultsService()
        userDefaultsService = uds
        profileService = ProfileService(userDefaultsService: uds)
        notificationService = NotificationService()
        affirmationService = AffirmationService(userDefaultsService: uds)
        purchaseService = PurchaseService(userDefaultsService: uds)
    }
}
