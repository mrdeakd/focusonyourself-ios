import Factory
import Foundation

final class HealthKitUseCase: HealthKitUseCaseProtocol {
    @Injected(\.healthKitService) private var healthKitService

    func save(mood: Mood, factors: CheckInFactors?) async {
        await healthKitService.save(mood: mood, factors: factors)
    }
}
