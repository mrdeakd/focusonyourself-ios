enum SubscriptionError: UserFacingError, Equatable {
    case unauthorized
    case invalidTransaction
    case verificationFailed

    var errorTitle: String {
        switch self {
        case .unauthorized:       "Sign in required"
        case .invalidTransaction: "Invalid transaction"
        case .verificationFailed: "Verification failed"
        }
    }

    var errorDescription: String? {
        switch self {
        case .unauthorized:       "Please sign in again to verify your subscription."
        case .invalidTransaction: "The transaction could not be verified."
        case .verificationFailed: "Please try again."
        }
    }
}
