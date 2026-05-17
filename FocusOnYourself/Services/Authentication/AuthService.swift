import Factory
import Foundation

final class AuthService: AuthServiceProtocol {
    @Injected(\.keychainService) private var keychain
    @Injected(\.networkClient) private var networkClient
    @Injected(\.profileService) private var profileService
    @Injected(\.checkinsService) private var checkinsService

    func register(email: String, password: String) async throws {
        let response: AuthResponse = try await networkClient.post(
            "/api/auth/register",
            body: LoginBody(email: email, password: password)
        )
        keychain.saveAuthTokens(access: response.accessToken, refresh: response.refreshToken, email: response.user.email)
        await uploadLocalCheckIns()
    }

    func signIn(email: String, password: String) async throws {
        let response: AuthResponse = try await networkClient.post(
            "/api/auth/login",
            body: LoginBody(email: email, password: password)
        )
        keychain.saveAuthTokens(access: response.accessToken, refresh: response.refreshToken, email: response.user.email)
        await downloadAndReplaceCheckIns()
    }

    func signOut() async {
        if let refresh = keychain.load(key: KeychainService.refreshTokenKey) {
            _ = try? await networkClient.post("/api/auth/logout", body: RefreshBody(refreshToken: refresh)) as EmptyResponse
        }
        keychain.clearAuthTokens()
    }

    func refreshTokenIfNeeded() async {
        guard let accessToken = keychain.load(key: KeychainService.accessTokenKey),
              jwtIsNearExpiry(accessToken) else {
            return
        }

        guard let refresh = keychain.load(key: KeychainService.refreshTokenKey) else {
            keychain.clearAuthTokens()
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
            keychain.clearAuthTokens()
        }
    }
}

// MARK: - Check-in sync

private extension AuthService {
    func uploadLocalCheckIns() async {
        let checkIns = profileService.profile.checkIns
        guard !checkIns.isEmpty else { return }
        try? await checkinsService.importAll(checkIns)
    }

    func downloadAndReplaceCheckIns() async {
        guard let checkIns = try? await checkinsService.fetch() else { return }
        await MainActor.run { profileService.replaceCheckIns(checkIns) }
    }
}

// MARK: - JWT helper

extension AuthService {
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

    private struct JWTPayload: Decodable {
        let exp: Double
    }
}
