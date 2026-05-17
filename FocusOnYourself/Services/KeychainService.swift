import Foundation
import Security

final class KeychainService {
    static let accessTokenKey  = "foy.accessToken"
    static let refreshTokenKey = "foy.refreshToken"
    static let userEmailKey    = "foy.userEmail"

    private let service = "FocusOnYourself"

    func save(key: String, value: String) throws {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }

    func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
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
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
}
