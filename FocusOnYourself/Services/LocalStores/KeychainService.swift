import Foundation
import SwiftSecurity

final class KeychainService: KeychainServiceProtocol {
    static let accessTokenKey  = "foy.accessToken"
    static let refreshTokenKey = "foy.refreshToken"
    static let userEmailKey    = "foy.userEmail"

    private let keychain = Keychain.default

    func save(key: String, value: String) throws {
        try keychain.store(value, query: query(for: key))
    }

    func load(key: String) -> String? {
        try? keychain.retrieve(query(for: key))
    }

    func delete(key: String) {
        _ = try? keychain.remove(query(for: key))
    }

    // MARK: - Auth token convenience

    func saveAuthTokens(access: String, refresh: String, email: String) {
        try? save(key: Self.accessTokenKey, value: access)
        try? save(key: Self.refreshTokenKey, value: refresh)
        try? save(key: Self.userEmailKey, value: email)
    }

    func clearAuthTokens() {
        delete(key: Self.accessTokenKey)
        delete(key: Self.refreshTokenKey)
        delete(key: Self.userEmailKey)
    }

    // MARK: - Private

    private func query(for key: String) -> SecItemQuery<GenericPassword> {
        var query = SecItemQuery<GenericPassword>()
        query.service = "FocusOnYourself"
        query.account = key
        return query
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
}
