import Foundation

final class UserDefaultsStore: UserDefaultsStoreProtocol {
    private let defaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard

    func data(for key: UserDefaultsKey) -> Data? {
        defaults.data(forKey: key.rawValue)
    }

    func setData(_ data: Data?, for key: UserDefaultsKey) {
        defaults.set(data, forKey: key.rawValue)
    }

    func bool(for key: UserDefaultsKey, defaultingTo defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key.rawValue) != nil else { return defaultValue }
        return defaults.bool(forKey: key.rawValue)
    }

    func setBool(_ value: Bool, for key: UserDefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }

    func string(for key: UserDefaultsKey) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    func setString(_ value: String?, for key: UserDefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }

    func remove(_ key: UserDefaultsKey) {
        defaults.removeObject(forKey: key.rawValue)
    }
}
