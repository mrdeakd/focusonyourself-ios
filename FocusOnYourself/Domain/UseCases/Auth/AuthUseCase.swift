import Factory
import Foundation

final class AuthUseCase: AuthUseCaseProtocol {
    @Injected(\.authRepository) private var authRepository
    @Injected(\.checkInRepository) private var checkInRepository
    @Injected(\.profileService) private var profileService

    func register(email: String, password: String) async throws {
        try await authRepository.register(email: email, password: password)
        try await checkInRepository.uploadAll(profileService.profile.checkIns)
    }

    func signIn(email: String, password: String) async throws {
        try await authRepository.login(email: email, password: password)
        let serverCheckIns = try await checkInRepository.fetchFromServer()
        try await checkInRepository.replaceAll(serverCheckIns)
    }

    func signOut() async {
        await authRepository.logout()
    }

    func refreshTokenIfNeeded() async {
        await authRepository.refreshTokenIfNeeded()
    }

    var email: String? { authRepository.email }
    var isAuthenticated: Bool { authRepository.isAuthenticated }
}
