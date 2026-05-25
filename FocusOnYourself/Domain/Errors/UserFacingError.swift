protocol UserFacingError: Error {
    var errorTitle: String { get }
    var errorDescription: String? { get }
}
