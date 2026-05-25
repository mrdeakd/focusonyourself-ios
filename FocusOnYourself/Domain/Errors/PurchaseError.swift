enum PurchaseError: UserFacingError, Equatable {
    case purchaseFailed
    case verificationFailed
    case userCancelled

    var errorTitle: String {
        switch self {
        case .purchaseFailed:     "Purchase failed"
        case .verificationFailed: "Verification failed"
        case .userCancelled:      "Purchase cancelled"
        }
    }

    var errorDescription: String? {
        switch self {
        case .purchaseFailed:     "The purchase could not be completed."
        case .verificationFailed: "Transaction verification failed."
        case .userCancelled:      "The purchase was cancelled."
        }
    }
}
