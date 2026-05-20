import Factory
import Foundation

final class AuthUseCase: AuthUseCaseProtocol {
    @Injected(\.authService) private var authService
    @Injected(\.checkInUseCase) private var checkInUseCase
    @Injected(\.keychainStore) private var keychainStore
    private let jwtExpiryChecker = JWTExpiryChecker()

    private static let accessTokenKey  = "foy.accessToken"
    private static let refreshTokenKey = "foy.refreshToken"
    private static let userEmailKey    = "foy.userEmail"

    var email: String? { keychainStore.load(Self.userEmailKey) }
    var isAuthenticated: Bool { keychainStore.load(Self.accessTokenKey) != nil }

    // MARK: - Public methods

    func register(email: String, password: String) async throws {
        let response = try await authService.register(email: email, password: password)
        saveAuthTokens(from: response)
        try? await checkInUseCase.uploadAllToServer()
    }

    func signIn(email: String, password: String) async throws {
        let response = try await authService.login(email: email, password: password)
        saveAuthTokens(from: response)
        try? await checkInUseCase.downloadAndReplaceFromServer()
    }

    func signOut() async {
        if let refresh = keychainStore.load(Self.refreshTokenKey) {
            try? await authService.logout(refreshToken: refresh)
        }
        clearAuthTokens()
    }

    func refreshTokenIfNeeded() async {
        guard let accessToken = keychainStore.load(Self.accessTokenKey) else { return }
        guard jwtExpiryChecker.isNearExpiry(accessToken) else { return }
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
}
