import Foundation

struct URLSessionNetworkClient: NetworkClientProtocol {
    private let baseURL = URL(string: "https://focusonyourself-backend.onrender.com")!
    private let keychain: KeychainService

    init(keychain: KeychainService) {
        self.keychain = keychain
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try buildRequest(path: path, method: "GET", body: nil as Data?)
        return try await perform(request)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let data = try JSONEncoder().encode(body)
        let request = try buildRequest(path: path, method: "POST", body: data)
        return try await perform(request)
    }

    // MARK: - Private

    private func buildRequest(path: String, method: String, body: Data?) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = keychain.load(key: KeychainService.accessTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(-1)
        }
        switch http.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 304:
            let cached = URLSession.shared.configuration.urlCache?
                .cachedResponse(for: request)?.data ?? data
            return try JSONDecoder().decode(T.self, from: cached)
        default:
            throw NetworkError.badResponse(http.statusCode)
        }
    }
}
