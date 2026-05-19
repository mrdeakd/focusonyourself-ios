import Factory
import Foundation
import SwiftSecurity

final class AuthUseCase: AuthUseCaseProtocol {
    @Injected(\.networkClient) private var networkClient
    @Injected(\.checkinsService) private var checkinsService
    @Injected(\.profileUseCase) private var profileUseCase

    private let keychain = Keychain.default

    private static let accessTokenKey  = "foy.accessToken"
    private static let refreshTokenKey = "foy.refreshToken"
    private static let userEmailKey    = "foy.userEmail"

    func register(email: String, password: String) async throws {
        let response: AuthResponse = try await networkClient.post(
            "/api/auth/register",
            body: LoginBody(email: email, password: password)
        )
        saveAuthTokens(access: response.accessToken, refresh: response.refreshToken, email: response.user.email)
        await uploadLocalCheckIns()
    }

    func signIn(email: String, password: String) async throws {
        let response: AuthResponse = try await networkClient.post(
            "/api/auth/login",
            body: LoginBody(email: email, password: password)
        )
        saveAuthTokens(access: response.accessToken, refresh: response.refreshToken, email: response.user.email)
        await downloadAndReplaceCheckIns()
    }

    func signOut() async {
        if let refresh = loadKeychain(Self.refreshTokenKey) {
            _ = try? await networkClient.post("/api/auth/logout", body: RefreshBody(refreshToken: refresh)) as EmptyResponse
        }
        clearAuthTokens()
    }

    func refreshTokenIfNeeded() async {
        guard let accessToken = loadKeychain(Self.accessTokenKey) else { return }
        guard jwtIsNearExpiry(accessToken) else { return }
        guard let refresh = loadKeychain(Self.refreshTokenKey) else {
            clearAuthTokens()
            return
        }
        do {
            let response: RefreshResponse = try await networkClient.post(
                "/api/auth/refresh",
                body: RefreshBody(refreshToken: refresh)
            )
            try? saveKeychain(Self.accessTokenKey, value: response.accessToken)
            try? saveKeychain(Self.refreshTokenKey, value: response.refreshToken)
        } catch {
            clearAuthTokens()
        }
    }

    var email: String? { loadKeychain(Self.userEmailKey) }
    var isAuthenticated: Bool { loadKeychain(Self.accessTokenKey) != nil }

    // MARK: - Keychain (inlined SwiftSecurity)

    private func saveAuthTokens(access: String, refresh: String, email: String) {
        try? saveKeychain(Self.accessTokenKey, value: access)
        try? saveKeychain(Self.refreshTokenKey, value: refresh)
        try? saveKeychain(Self.userEmailKey, value: email)
    }

    private func clearAuthTokens() {
        deleteKeychain(Self.accessTokenKey)
        deleteKeychain(Self.refreshTokenKey)
        deleteKeychain(Self.userEmailKey)
    }

    private func saveKeychain(_ key: String, value: String) throws {
        try keychain.store(value, query: keychainQuery(for: key))
    }

    private func loadKeychain(_ key: String) -> String? {
        try? keychain.retrieve(keychainQuery(for: key))
    }

    private func deleteKeychain(_ key: String) {
        _ = try? keychain.remove(keychainQuery(for: key))
    }

    private func keychainQuery(for key: String) -> SecItemQuery<GenericPassword> {
        var query = SecItemQuery<GenericPassword>()
        query.service = "FocusOnYourself"
        query.account = key
        return query
    }

    // MARK: - Check-in sync

    private func uploadLocalCheckIns() async {
        let checkIns = profileUseCase.profile.checkIns
        guard !checkIns.isEmpty else { return }
        try? await checkinsService.importAll(checkIns)
    }

    private func downloadAndReplaceCheckIns() async {
        guard let checkIns = try? await checkinsService.fetch() else { return }
        var profile = profileUseCase.profile
        profile.checkIns = checkIns
        profileUseCase.updateProfile(profile)
    }

    // MARK: - JWT

    private func jwtIsNearExpiry(_ token: String) -> Bool {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count == 3 else { return true }
        var payload = parts[1]
        let remainder = payload.count % 4
        if remainder != 0 { payload += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: payload) else { return true }
        guard let jwt = try? JSONDecoder().decode(JWTPayload.self, from: data) else { return true }
        return jwt.exp - Date().timeIntervalSince1970 < 60
    }

    private struct JWTPayload: Decodable {
        let exp: Double
    }
}
