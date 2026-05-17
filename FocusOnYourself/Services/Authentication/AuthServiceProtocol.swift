protocol AuthServiceProtocol {
    func register(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() async
    func refreshTokenIfNeeded() async
}
