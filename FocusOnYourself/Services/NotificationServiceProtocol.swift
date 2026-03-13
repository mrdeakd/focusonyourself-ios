import Foundation

protocol NotificationServiceProtocol: AnyObject {
    func requestPermission() async -> Bool
    func schedule(name: String)
    func cancel()
}
