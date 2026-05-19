protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(email: String, password: String) async throws -> AuthResponse
    func logout(refreshToken: String) async throws
    func refresh(refreshToken: String) async throws -> RefreshResponse
}
