import Factory
import Foundation
import Observation

private struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser
}

private struct AuthUser: Decodable {
    let id: String
    let email: String
}

private struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

private struct LoginBody: Encodable {
    let email: String
    let password: String
}

private struct RefreshBody: Encodable {
    let refreshToken: String
}

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
        try? keychain.save(key: KeychainService.accessTokenKey, value: access)
        try? keychain.save(key: KeychainService.refreshTokenKey, value: refresh)
        try? keychain.save(key: KeychainService.userEmailKey, value: email)
        isAuthenticated = true
        userEmail = email
    }

    private func clearTokens() {
        keychain.delete(key: KeychainService.accessTokenKey)
        keychain.delete(key: KeychainService.refreshTokenKey)
        keychain.delete(key: KeychainService.userEmailKey)
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
            let json = try? JSONDecoder().decode([String: AnyCodable].self, from: data),
            let exp = json["exp"]?.doubleValue else { return true }
        return exp - Date().timeIntervalSince1970 < 60
    }
}

// Minimal Codable helpers
private struct EmptyResponse: Decodable {}

private struct AnyCodable: Decodable {
    let doubleValue: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        doubleValue = try? container.decode(Double.self)
    }
}
