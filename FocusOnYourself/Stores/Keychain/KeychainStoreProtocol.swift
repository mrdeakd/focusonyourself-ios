protocol KeychainStoreProtocol {
    func save(_ value: String, for key: String) throws
    func load(_ key: String) -> String?
    func delete(_ key: String)
}
