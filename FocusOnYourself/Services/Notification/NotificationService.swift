import Foundation
import UserNotifications

final class NotificationService: NotificationServiceProtocol {
    static let notificationID = "daily-affirmation"

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func schedule(name: String) {
        let content = UNMutableNotificationContent()
        content.title = name.isEmpty ?
        "Good morning ✨" :
        "Good morning, \(name) ✨"
        content.body  = "Log your mood & today's context."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger)
        )
    }

    func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }
}
