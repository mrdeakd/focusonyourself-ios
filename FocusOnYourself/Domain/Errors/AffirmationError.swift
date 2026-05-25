enum AffirmationError: UserFacingError, Equatable {
    case fetchFailed

    var errorTitle: String { "Couldn't load affirmations" }
    var errorDescription: String? { nil }
}
