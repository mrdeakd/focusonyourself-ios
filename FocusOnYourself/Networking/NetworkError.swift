enum NetworkError: Error {
    case invalidURL
    case badResponse(Int)

    var statusCode: Int? {
        if case .badResponse(let code) = self {
            return code
        }
        return nil
    }
}
