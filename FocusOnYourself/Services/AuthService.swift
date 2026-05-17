import Factory
import Foundation
import Observation

@Observable @MainActor
final class AuthService: AuthServiceProtocol {
    private(set) var isAuthenticated = false
    private(set) var userEmail: String?

    @ObservationIgnored private let keychain: KeychainService
    @ObservationIgnored private let networkClient: NetworkClientProtocol

    init(keychain: KeychainService, networkClient: NetworkClientProtocol) {
        self.keychain = keychain
        self.networkClient = networkClient
        if let token = keychain.load(key: KeychainService.accessTokenKey), !token.isEmpty {
            isAuthenticated = true
            userEmail = keychain.load(key: KeychainService.userEmailKey)
        }
    }

    func register(email: String, password: String) async throws {
        let response: AuthResponse = try await networkClient.post(
            "/api/auth/register",
            body: LoginBody(email: email, password: password)
        )
        storeTokens(access: response.accessToken, refresh: response.refreshToken, email: response.user.email)
    }

    func signIn(email: String, password: String) async throws {
        let response: AuthResponse = try await networkClient.post(
            "/api/auth/login",
            body: LoginBody(email: email, password: password)
        )
        storeTokens(access: response.accessToken, refresh: response.refreshToken, email: response.user.email)
    }

    func signOut() async {
        if let refresh = keychain.load(key: KeychainService.refreshTokenKey) {
            _ = try? await networkClient.post("/api/auth/logout", body: RefreshBody(refreshToken: refresh)) as EmptyResponse
        }
        clearTokens()
    }

    func refreshTokenIfNeeded() async {
        guard let accessToken = keychain.load(key: KeychainService.accessTokenKey),
            jwtIsNearExpiry(accessToken) else { return }

        guard let refresh = keychain.load(key: KeychainService.refreshTokenKey) else {
            clearTokens()
            return
        }

        do {
            let response: RefreshResponse = try await networkClient.post(
                "/api/auth/refresh",
                body: RefreshBody(refreshToken: refresh)
            )
            try? keychain.save(key: KeychainService.accessTokenKey, value: response.accessToken)
            try? keychain.save(key: KeychainService.refreshTokenKey, value: response.refreshToken)
        } catch {
            clearTokens()
        }
    }

    // MARK: - Private

    private func storeTokens(access: String, refresh: String, email: String) {
        keychain.saveAuthTokens(access: access, refresh: refresh, email: email)
        isAuthenticated = true
        userEmail = email
    }

    private func clearTokens() {
        keychain.clearAuthTokens()
        isAuthenticated = false
        userEmail = nil
    }

    private func jwtIsNearExpiry(_ token: String) -> Bool {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count == 3 else { return true }
        var payload = parts[1]
        let remainder = payload.count % 4
        if remainder != 0 { payload += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: payload),
            let jwt = try? JSONDecoder().decode(JWTPayload.self, from: data) else { return true }
        return jwt.exp - Date().timeIntervalSince1970 < 60
    }
}

private struct JWTPayload: Decodable {
    let exp: Double
}
