import Factory
import Foundation

final class AuthUseCase: AuthUseCaseProtocol {
    @Injected(\.authService) private var authService
    @Injected(\.checkinsService) private var checkinsService
    @Injected(\.profileUseCase) private var profileUseCase
    @Injected(\.keychainStore) private var keychainStore

    private static let accessTokenKey  = "foy.accessToken"
    private static let refreshTokenKey = "foy.refreshToken"
    private static let userEmailKey    = "foy.userEmail"

    func register(email: String, password: String) async throws {
        let response = try await authService.register(email: email, password: password)
        saveAuthTokens(from: response)
        await uploadLocalCheckIns()
    }

    func signIn(email: String, password: String) async throws {
        let response = try await authService.login(email: email, password: password)
        saveAuthTokens(from: response)
        await downloadAndReplaceCheckIns()
    }

    func signOut() async {
        if let refresh = keychainStore.load(Self.refreshTokenKey) {
            try? await authService.logout(refreshToken: refresh)
        }
        clearAuthTokens()
    }

    func refreshTokenIfNeeded() async {
        guard let accessToken = keychainStore.load(Self.accessTokenKey) else { return }
        guard jwtIsNearExpiry(accessToken) else { return }
        guard let refresh = keychainStore.load(Self.refreshTokenKey) else {
            clearAuthTokens()
            return
        }
        do {
            let response = try await authService.refresh(refreshToken: refresh)
            try? keychainStore.save(response.accessToken, for: Self.accessTokenKey)
            try? keychainStore.save(response.refreshToken, for: Self.refreshTokenKey)
        } catch {
            clearAuthTokens()
        }
    }

    var email: String? { keychainStore.load(Self.userEmailKey) }
    var isAuthenticated: Bool { keychainStore.load(Self.accessTokenKey) != nil }

    // MARK: - Token persistence

    private func saveAuthTokens(from response: AuthResponse) {
        try? keychainStore.save(response.accessToken, for: Self.accessTokenKey)
        try? keychainStore.save(response.refreshToken, for: Self.refreshTokenKey)
        try? keychainStore.save(response.user.email, for: Self.userEmailKey)
    }

    private func clearAuthTokens() {
        keychainStore.delete(Self.accessTokenKey)
        keychainStore.delete(Self.refreshTokenKey)
        keychainStore.delete(Self.userEmailKey)
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
