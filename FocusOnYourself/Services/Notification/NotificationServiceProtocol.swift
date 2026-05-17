import Foundation

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func schedule(name: String)
    func cancel()
}
