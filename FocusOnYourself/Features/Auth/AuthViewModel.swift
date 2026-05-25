import Factory
import Observation

@Observable @MainActor
final class AuthViewModel {
    @ObservationIgnored @Injected(\.authUseCase) private var authUseCase

    // MARK: - State

    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var isAuthenticated = false
    var error: ErrorInfo?

    // MARK: - Public methods

    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            try await authUseCase.signIn(email: email, password: password)
            isAuthenticated = true
        } catch let error as AuthError {
            self.error = ErrorInfo(error)
        } catch {
            self.error = ErrorInfo(title: "Sign in failed", description: "Please try again.")
        }
    }

    func register() async {
        guard password == confirmPassword else {
            error = ErrorInfo(title: "Passwords do not match")
            return
        }
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            try await authUseCase.register(email: email, password: password)
            isAuthenticated = true
        } catch let error as AuthError {
            self.error = ErrorInfo(error)
        } catch {
            self.error = ErrorInfo(title: "Registration failed", description: "Please try again.")
        }
    }
}
