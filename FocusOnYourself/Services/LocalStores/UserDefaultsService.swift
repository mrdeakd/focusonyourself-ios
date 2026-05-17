import Foundation

final class UserDefaultsService: UserDefaultsServiceProtocol {
    private let appGroupDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard

    init() {
        migrateFromKVSIfNeeded()
    }

    // One-time migration: copy userProfile from iCloud KVS to local defaults on upgrade
    private func migrateFromKVSIfNeeded() {
        let kvs = NSUbiquitousKeyValueStore.default
        kvs.synchronize()
        let key = UserDefaultsKey.userProfile.rawValue
        if appGroupDefaults.data(forKey: key) == nil, let kvsData = kvs.data(forKey: key) {
            appGroupDefaults.set(kvsData, forKey: key)
        }
    }

    func getData(_ key: UserDefaultsKey) -> Data? {
        appGroupDefaults.data(forKey: key.rawValue)
    }

    func setData(_ key: UserDefaultsKey, value: Data?) {
        appGroupDefaults.set(value, forKey: key.rawValue)
    }

    func getBool(_ key: UserDefaultsKey) -> Bool {
        appGroupDefaults.bool(forKey: key.rawValue)
    }

    func setBool(_ key: UserDefaultsKey, value: Bool) {
        appGroupDefaults.set(value, forKey: key.rawValue)
    }

    func getLocalBool(_ key: UserDefaultsKey, defaultingTo defaultValue: Bool) -> Bool {
        guard appGroupDefaults.object(forKey: key.rawValue) != nil else { return defaultValue }
        return appGroupDefaults.bool(forKey: key.rawValue)
    }

    func setLocalBool(_ key: UserDefaultsKey, value: Bool) {
        appGroupDefaults.set(value, forKey: key.rawValue)
    }

    func getString(_ key: UserDefaultsKey) -> String? {
        appGroupDefaults.string(forKey: key.rawValue)
    }

    func setString(_ key: UserDefaultsKey, value: String?) {
        appGroupDefaults.set(value, forKey: key.rawValue)
    }

    func getLocalData(_ key: UserDefaultsKey) -> Data? {
        appGroupDefaults.data(forKey: key.rawValue)
    }

    func clearLocalData(_ key: UserDefaultsKey) {
        appGroupDefaults.removeObject(forKey: key.rawValue)
    }
}
