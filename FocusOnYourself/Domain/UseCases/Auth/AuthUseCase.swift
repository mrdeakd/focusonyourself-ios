import Factory
import Foundation
import Observation

@Observable
@MainActor
final class AuthUseCase: AuthUseCaseProtocol {
    private(set) var isAuthenticated: Bool
    private(set) var email: String?

    @ObservationIgnored @Injected(\.authService) private var authService
    @ObservationIgnored @Injected(\.checkInUseCase) private var checkInUseCase
    @ObservationIgnored @Injected(\.keychainStore) private var keychainStore
    @ObservationIgnored private let jwtExpiryCalculator = JWTExpiryCalculator()

    private static let accessTokenKey  = "foy.accessToken"
    private static let refreshTokenKey = "foy.refreshToken"
    private static let userEmailKey    = "foy.userEmail"

    init() {
        let keychain = _keychainStore.wrappedValue
        isAuthenticated = keychain.load(Self.accessTokenKey) != nil
        email = keychain.load(Self.userEmailKey)
    }

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
        guard jwtExpiryCalculator.isNearExpiry(accessToken) else { return }
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
        isAuthenticated = true
        email = response.user.email
    }

    private func clearAuthTokens() {
        keychainStore.delete(Self.accessTokenKey)
        keychainStore.delete(Self.refreshTokenKey)
        keychainStore.delete(Self.userEmailKey)
        isAuthenticated = false
        email = nil
    }
}
