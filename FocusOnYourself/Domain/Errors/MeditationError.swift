enum MeditationError: UserFacingError, Equatable {
    case fetchFailed

    var errorTitle: String { "Couldn't load meditations" }
    var errorDescription: String? { "Please try again." }
}
