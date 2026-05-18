import Foundation

protocol NotificationsUseCaseProtocol: AnyObject {
    func requestPermission() async -> Bool
    func schedule(name: String)
    func cancel()
}
