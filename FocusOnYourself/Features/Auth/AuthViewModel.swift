import Factory
import Observation

@Observable @MainActor
final class AuthViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var isAuthenticated = false
    var error: ErrorInfo?

    @ObservationIgnored @Injected(\.authService) private var authService

    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            try await authService.signIn(email: email, password: password)
            isAuthenticated = true
        } catch let networkError as NetworkError {
            if case .badResponse(let code) = networkError, code == 401 {
                error = ErrorInfo(title: "Incorrect email or password")
            } else {
                error = ErrorInfo(title: "Sign in failed", description: "Please try again.")
            }
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
            try await authService.register(email: email, password: password)
            isAuthenticated = true
        } catch let networkError as NetworkError {
            if case .badResponse(let code) = networkError, code == 409 {
                error = ErrorInfo(title: "Email already in use")
            } else {
                error = ErrorInfo(title: "Registration failed", description: "Please try again.")
            }
        } catch {
            self.error = ErrorInfo(title: "Registration failed", description: "Please try again.")
        }
    }
}
