import Foundation

final class UserDefaultsService: UserDefaultsServiceProtocol {
    private let kvs = NSUbiquitousKeyValueStore.default
    private let appGroupDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard

    init() {
        migrateIfNeeded()
        kvs.synchronize()
    }

    private func migrateIfNeeded() {
        if kvs.data(forKey: UserDefaultsKey.userProfile.rawValue) == nil,
           let existing = appGroupDefaults.data(forKey: UserDefaultsKey.userProfile.rawValue) {
            kvs.set(existing, forKey: UserDefaultsKey.userProfile.rawValue)
        }
    }

    func getData(_ key: UserDefaultsKey) -> Data? {
        kvs.data(forKey: key.rawValue)
    }

    private func store(_ value: Any?, forKey key: UserDefaultsKey) {
        kvs.set(value, forKey: key.rawValue)
        appGroupDefaults.set(value, forKey: key.rawValue)
    }

    func setData(_ key: UserDefaultsKey, value: Data?) {
        store(value, forKey: key)
    }

    func getBool(_ key: UserDefaultsKey) -> Bool {
        kvs.bool(forKey: key.rawValue)
    }

    func setBool(_ key: UserDefaultsKey, value: Bool) {
        store(value, forKey: key)
    }

    func getString(_ key: UserDefaultsKey) -> String? {
        kvs.string(forKey: key.rawValue)
    }

    func setString(_ key: UserDefaultsKey, value: String?) {
        store(value, forKey: key)
    }
}
