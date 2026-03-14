import Foundation

final class ServiceContainer {
    static let shared = ServiceContainer()
    let profileService = ProfileService()
    let notificationService = NotificationService()
    let affirmationService: AffirmationServiceProtocol = AffirmationService()
    let purchaseService = PurchaseService()
    private init() {}
}
