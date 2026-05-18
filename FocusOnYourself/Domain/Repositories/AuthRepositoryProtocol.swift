import Foundation

protocol AuthRepositoryProtocol: AnyObject {
    func login(email: String, password: String) async throws
    func register(email: String, password: String) async throws
    func logout() async
    func refreshTokenIfNeeded() async

    var email: String? { get }
    var isAuthenticated: Bool { get }
}
