import Factory
import Foundation

final class CheckInUseCase: CheckInUseCaseProtocol {
    @Injected(\.checkInRepository) private var repository
    @Injected(\.profileService) private var profileService
    private let calculator = StreakCalculator()

    func record(mood: Mood, feelingsDescription: String?, factors: CheckInFactors?) async throws {
        let checkIn = CheckIn(
            dateString: CheckIn.dateString(for: .now),
            mood: mood,
            feelingsDescription: feelingsDescription,
            factors: factors
        )
        try await repository.save(checkIn)
    }

    func replaceAll(_ checkIns: [CheckIn]) async throws {
        try await repository.replaceAll(checkIns)
    }

    func mergeWidgetCheckIn() {
        repository.mergePendingWidgetCheckIn()
    }

    func reset() {
        repository.reset()
    }

    var hasCheckedInToday: Bool {
        profileService.profile.checkIns.contains { $0.dateString == CheckIn.dateString(for: .now) }
    }

    var todaysMood: Mood? {
        profileService.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.mood
    }

    var todaysFeelingsDescription: String? {
        profileService.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.feelingsDescription
    }

    var todaysFactors: CheckInFactors? {
        profileService.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.factors
    }

    var earliestCheckInDate: Date? {
        profileService.profile.checkIns.map { $0.date }.min()
    }

    func streakStats() -> (current: Int, longest: Int) {
        calculator.compute(checkIns: profileService.profile.checkIns)
    }

    func streakStartDate() -> Date? {
        calculator.startDate(checkIns: profileService.profile.checkIns)
    }

    var allCheckIns: [CheckIn] { profileService.profile.checkIns }

    func checkIn(for dateString: String) -> CheckIn? {
        profileService.profile.checkIns.first { $0.dateString == dateString }
    }
}
