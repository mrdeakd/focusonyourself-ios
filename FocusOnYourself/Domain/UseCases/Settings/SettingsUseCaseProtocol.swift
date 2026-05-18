import Foundation

protocol SettingsUseCaseProtocol: AnyObject {
    var showSleepFactor: Bool { get set }
    var showStressFactor: Bool { get set }
    var showExerciseFactor: Bool { get set }
    var showSocialFactor: Bool { get set }

    func resetFactorToggles()
    func clearPendingWidgetCheckIn()
}
