import Factory
import Foundation

final class SettingsUseCase: SettingsUseCaseProtocol {
    @Injected(\.userDefaultsStore) private var userDefaultsStore

    var showSleepFactor: Bool {
        get { userDefaultsStore.bool(for: .showSleepFactor, defaultingTo: true) }
        set { userDefaultsStore.setBool(newValue, for: .showSleepFactor) }
    }

    var showStressFactor: Bool {
        get { userDefaultsStore.bool(for: .showStressFactor, defaultingTo: true) }
        set { userDefaultsStore.setBool(newValue, for: .showStressFactor) }
    }

    var showExerciseFactor: Bool {
        get { userDefaultsStore.bool(for: .showExerciseFactor, defaultingTo: true) }
        set { userDefaultsStore.setBool(newValue, for: .showExerciseFactor) }
    }

    var showSocialFactor: Bool {
        get { userDefaultsStore.bool(for: .showSocialFactor, defaultingTo: true) }
        set { userDefaultsStore.setBool(newValue, for: .showSocialFactor) }
    }

    func resetFactorToggles() {
        userDefaultsStore.setBool(true, for: .showSleepFactor)
        userDefaultsStore.setBool(true, for: .showStressFactor)
        userDefaultsStore.setBool(true, for: .showExerciseFactor)
        userDefaultsStore.setBool(true, for: .showSocialFactor)
    }

    func clearPendingWidgetCheckIn() {
        userDefaultsStore.remove(.pendingWidgetCheckIn)
    }
}
