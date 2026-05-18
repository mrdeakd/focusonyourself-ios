import Factory
import Foundation

final class SettingsUseCase: SettingsUseCaseProtocol {
    @Injected(\.userDefaultsService) private var userDefaultsService

    var showSleepFactor: Bool {
        get { userDefaultsService.getLocalBool(.showSleepFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showSleepFactor, value: newValue) }
    }

    var showStressFactor: Bool {
        get { userDefaultsService.getLocalBool(.showStressFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showStressFactor, value: newValue) }
    }

    var showExerciseFactor: Bool {
        get { userDefaultsService.getLocalBool(.showExerciseFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showExerciseFactor, value: newValue) }
    }

    var showSocialFactor: Bool {
        get { userDefaultsService.getLocalBool(.showSocialFactor, defaultingTo: true) }
        set { userDefaultsService.setLocalBool(.showSocialFactor, value: newValue) }
    }

    func resetFactorToggles() {
        userDefaultsService.setLocalBool(.showSleepFactor, value: true)
        userDefaultsService.setLocalBool(.showStressFactor, value: true)
        userDefaultsService.setLocalBool(.showExerciseFactor, value: true)
        userDefaultsService.setLocalBool(.showSocialFactor, value: true)
    }

    func clearPendingWidgetCheckIn() {
        userDefaultsService.clearLocalData(.pendingWidgetCheckIn)
    }
}
