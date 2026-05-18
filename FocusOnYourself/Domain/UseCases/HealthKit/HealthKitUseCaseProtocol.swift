import Foundation

protocol HealthKitUseCaseProtocol: AnyObject {
    func save(mood: Mood, factors: CheckInFactors?) async
}
