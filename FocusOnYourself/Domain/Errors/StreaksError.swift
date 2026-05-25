enum StreaksError: UserFacingError, Equatable {
    case unauthorized
    case fetchFailed

    var errorTitle: String {
        switch self {
        case .unauthorized: "Sign in required"
        case .fetchFailed:  "Couldn't load streaks"
        }
    }

    var errorDescription: String? {
        switch self {
        case .unauthorized: "Please sign in again."
        case .fetchFailed:  "Please try again."
        }
    }
}
