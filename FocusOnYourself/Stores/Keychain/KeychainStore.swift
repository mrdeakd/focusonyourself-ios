import Foundation
import SwiftSecurity

final class KeychainStore: KeychainStoreProtocol {
    private let keychain = Keychain.default
    private let service = "FocusOnYourself"

    func save(_ value: String, for key: String) throws {
        try keychain.store(value, query: query(for: key))
    }

    func load(_ key: String) -> String? {
        try? keychain.retrieve(query(for: key))
    }

    func delete(_ key: String) {
        _ = try? keychain.remove(query(for: key))
    }

    private func query(for key: String) -> SecItemQuery<GenericPassword> {
        var itemQuery = SecItemQuery<GenericPassword>()
        itemQuery.service = service
        itemQuery.account = key
        return itemQuery
    }
}
