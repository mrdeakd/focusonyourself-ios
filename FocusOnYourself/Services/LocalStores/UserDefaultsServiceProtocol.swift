import Foundation

protocol UserDefaultsServiceProtocol {
    func getData(_ key: UserDefaultsKey) -> Data?
    func setData(_ key: UserDefaultsKey, value: Data?)
    func getBool(_ key: UserDefaultsKey) -> Bool
    func setBool(_ key: UserDefaultsKey, value: Bool)
    func getLocalBool(_ key: UserDefaultsKey, defaultingTo defaultValue: Bool) -> Bool
    func setLocalBool(_ key: UserDefaultsKey, value: Bool)
    func getString(_ key: UserDefaultsKey) -> String?
    func setString(_ key: UserDefaultsKey, value: String?)
    func getLocalData(_ key: UserDefaultsKey) -> Data?
    func clearLocalData(_ key: UserDefaultsKey)
}
