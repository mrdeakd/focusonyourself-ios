import Factory
import Foundation

final class AuthService: AuthServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func login(email: String, password: String) async throws -> AuthResponse {
        let path = "/api/auth/login"
        let body = LoginBody(email: email, password: password)
        let response: AuthResponse = try await networkClient.post(path, body: body)
        return response
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        let path = "/api/auth/register"
        let body = LoginBody(email: email, password: password)
        let response: AuthResponse = try await networkClient.post(path, body: body)
        return response
    }

    func logout(refreshToken: String) async throws {
        let path = "/api/auth/logout"
        let body = RefreshBody(refreshToken: refreshToken)
        let _: EmptyResponse = try await networkClient.post(path, body: body)
    }

    func refresh(refreshToken: String) async throws -> RefreshResponse {
        let path = "/api/auth/refresh"
        let body = RefreshBody(refreshToken: refreshToken)
        let response: RefreshResponse = try await networkClient.post(path, body: body)
        return response
    }
}
