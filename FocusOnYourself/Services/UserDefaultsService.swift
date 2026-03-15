import Foundation

final class UserDefaultsService: UserDefaultsServiceProtocol {
    private let defaults = UserDefaults.standard

    func getData(_ key: UserDefaultsKey) -> Data? {
        defaults.data(forKey: key.rawValue)
    }

    func setData(_ key: UserDefaultsKey, value: Data?) {
        defaults.set(value, forKey: key.rawValue)
    }

    func getBool(_ key: UserDefaultsKey) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    func setBool(_ key: UserDefaultsKey, value: Bool) {
        defaults.set(value, forKey: key.rawValue)
    }

    func getString(_ key: UserDefaultsKey) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    func setString(_ key: UserDefaultsKey, value: String?) {
        defaults.set(value, forKey: key.rawValue)
    }
}
