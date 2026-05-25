import Factory
import Foundation

final class AuthService: AuthServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func login(email: String, password: String) async throws -> AuthResponse {
        let path = "/api/auth/login"
        let body = LoginBody(email: email, password: password)
        do {
            let response: AuthResponse = try await networkClient.post(path, body: body)
            return response
        } catch {
            throw Self.mapLoginError(error)
        }
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        let path = "/api/auth/register"
        let body = LoginBody(email: email, password: password)
        do {
            let response: AuthResponse = try await networkClient.post(path, body: body)
            return response
        } catch {
            throw Self.mapRegisterError(error)
        }
    }

    func logout(refreshToken: String) async throws {
        let path = "/api/auth/logout"
        let body = RefreshBody(refreshToken: refreshToken)
        do {
            let _: EmptyResponse = try await networkClient.post(path, body: body)
        } catch {
            throw Self.mapLogoutError(error)
        }
    }

    func refresh(refreshToken: String) async throws -> RefreshResponse {
        let path = "/api/auth/refresh"
        let body = RefreshBody(refreshToken: refreshToken)
        do {
            let response: RefreshResponse = try await networkClient.post(path, body: body)
            return response
        } catch {
            throw Self.mapRefreshError(error)
        }
    }

    private static func mapLoginError(_ error: Error) -> AuthError {
        switch (error as? NetworkError)?.statusCode {
        case 401: .invalidCredentials
        default:  .signInFailed
        }
    }

    private static func mapRegisterError(_ error: Error) -> AuthError {
        switch (error as? NetworkError)?.statusCode {
        case 409: .emailAlreadyInUse
        default:  .registrationFailed
        }
    }

    private static func mapLogoutError(_ error: Error) -> AuthError { .logoutFailed }
    private static func mapRefreshError(_ error: Error) -> AuthError { .tokenRefreshFailed }
}
