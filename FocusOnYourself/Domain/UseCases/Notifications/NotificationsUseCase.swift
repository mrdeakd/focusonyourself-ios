import Factory
import Foundation

final class NotificationsUseCase: NotificationsUseCaseProtocol {
    @Injected(\.notificationService) private var notificationService

    func requestPermission() async -> Bool {
        await notificationService.requestPermission()
    }

    func schedule(name: String) {
        notificationService.schedule(name: name)
    }

    func cancel() {
        notificationService.cancel()
    }
}
