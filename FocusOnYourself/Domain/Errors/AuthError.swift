enum AuthError: UserFacingError, Equatable {
    case invalidCredentials
    case emailAlreadyInUse
    case signInFailed
    case registrationFailed
    case tokenRefreshFailed
    case logoutFailed

    var errorTitle: String {
        switch self {
        case .invalidCredentials:   "Incorrect email or password"
        case .emailAlreadyInUse:    "Email already in use"
        case .signInFailed:         "Sign in failed"
        case .registrationFailed:   "Registration failed"
        case .tokenRefreshFailed:   "Session expired"
        case .logoutFailed:         "Sign out failed"
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:   nil
        case .emailAlreadyInUse:    nil
        case .signInFailed:         "Please try again."
        case .registrationFailed:   "Please try again."
        case .tokenRefreshFailed:   "Please sign in again."
        case .logoutFailed:         "Please try again."
        }
    }
}
