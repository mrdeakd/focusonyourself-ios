import Foundation

protocol UserDefaultsStoreProtocol {
    func data(for key: UserDefaultsKey) -> Data?
    func setData(_ data: Data?, for key: UserDefaultsKey)
    func bool(for key: UserDefaultsKey, defaultingTo defaultValue: Bool) -> Bool
    func setBool(_ value: Bool, for key: UserDefaultsKey)
    func string(for key: UserDefaultsKey) -> String?
    func setString(_ value: String?, for key: UserDefaultsKey)
    func remove(_ key: UserDefaultsKey)
}
