import Foundation

protocol KeychainServiceProtocol {
    func save(key: String, value: String) throws
    func load(key: String) -> String?
    func delete(key: String)
    func saveAuthTokens(access: String, refresh: String, email: String)
    func clearAuthTokens()
}
