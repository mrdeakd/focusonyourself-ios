enum CheckInError: UserFacingError, Equatable {
    case postFailed
    case importFailed
    case fetchFailed

    var errorTitle: String {
        switch self {
        case .postFailed:   "Couldn't save check-in"
        case .importFailed: "Couldn't sync check-ins"
        case .fetchFailed:  "Couldn't load check-ins"
        }
    }

    var errorDescription: String? {
        "Please try again."
    }
}
