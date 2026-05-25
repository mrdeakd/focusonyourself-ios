enum ArticlesError: UserFacingError, Equatable {
    case fetchFailed

    var errorTitle: String { "Couldn't load articles" }
    var errorDescription: String? { nil }
}
