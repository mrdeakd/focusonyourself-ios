import Foundation

final class SettingsUseCase: SettingsUseCaseProtocol {
    private let defaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard

    var showSleepFactor: Bool {
        get { getLocalBool(.showSleepFactor, defaultingTo: true) }
        set { defaults.set(newValue, forKey: UserDefaultsKey.showSleepFactor.rawValue) }
    }

    var showStressFactor: Bool {
        get { getLocalBool(.showStressFactor, defaultingTo: true) }
        set { defaults.set(newValue, forKey: UserDefaultsKey.showStressFactor.rawValue) }
    }

    var showExerciseFactor: Bool {
        get { getLocalBool(.showExerciseFactor, defaultingTo: true) }
        set { defaults.set(newValue, forKey: UserDefaultsKey.showExerciseFactor.rawValue) }
    }

    var showSocialFactor: Bool {
        get { getLocalBool(.showSocialFactor, defaultingTo: true) }
        set { defaults.set(newValue, forKey: UserDefaultsKey.showSocialFactor.rawValue) }
    }

    func resetFactorToggles() {
        defaults.set(true, forKey: UserDefaultsKey.showSleepFactor.rawValue)
        defaults.set(true, forKey: UserDefaultsKey.showStressFactor.rawValue)
        defaults.set(true, forKey: UserDefaultsKey.showExerciseFactor.rawValue)
        defaults.set(true, forKey: UserDefaultsKey.showSocialFactor.rawValue)
    }

    func clearPendingWidgetCheckIn() {
        defaults.removeObject(forKey: UserDefaultsKey.pendingWidgetCheckIn.rawValue)
    }

    private func getLocalBool(_ key: UserDefaultsKey, defaultingTo defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key.rawValue) != nil else { return defaultValue }
        return defaults.bool(forKey: key.rawValue)
    }
}
