import Foundation

struct URLSessionNetworkClient: NetworkClientProtocol {
    private let baseURL = URL(string: "https://focusonyourself-backend.onrender.com")!

    func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        let request = URLRequest(url: url)
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
