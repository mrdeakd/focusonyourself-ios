import Foundation

protocol AuthUseCaseProtocol: AnyObject {
    func register(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() async
    func refreshTokenIfNeeded() async

    var email: String? { get }
    var isAuthenticated: Bool { get }
}
