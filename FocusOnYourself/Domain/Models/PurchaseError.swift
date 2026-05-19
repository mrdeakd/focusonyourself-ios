enum PurchaseError: Error, Equatable {
    case purchaseFailed
    case verificationFailed
    case userCancelled

    var defaultDescription: String {
        switch self {
        case .purchaseFailed:      return "The purchase could not be completed."
        case .verificationFailed:  return "Transaction verification failed."
        case .userCancelled:       return "The purchase was cancelled."
        }
    }
}
