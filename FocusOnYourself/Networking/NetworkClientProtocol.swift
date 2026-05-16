protocol NetworkClientProtocol {
    func get<T: Decodable>(_ path: String) async throws -> T
}
