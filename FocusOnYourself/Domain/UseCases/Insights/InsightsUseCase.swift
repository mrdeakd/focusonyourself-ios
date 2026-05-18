import Factory
import Foundation

final class InsightsUseCase: InsightsUseCaseProtocol {
    @Injected(\.profileService) private var profileService
    private let calculator = InsightsCalculator()

    private var checkIns: [CheckIn] { profileService.profile.checkIns }

    func recentCheckIns(days: Int) -> [CheckIn] {
        calculator.recentCheckIns(from: checkIns, days: days)
    }

    func checkInCount(days: Int) -> Int {
        calculator.checkInCount(from: checkIns, days: days)
    }

    func averageMood(days: Int) -> Mood? {
        calculator.averageMood(from: checkIns, days: days)
    }

    func averageMoodText(days: Int) -> String {
        calculator.averageMoodText(from: checkIns, days: days)
    }

    func dailyMoodData(days: Int) -> [(label: String, checkIn: CheckIn?)] {
        calculator.dailyMoodData(from: checkIns, days: days)
    }

    func weeklyAverages() -> [(week: String, avg: Double)] {
        calculator.weeklyAverages(from: checkIns)
    }

    func monthlyAverages() -> [(month: String, avg: Double)] {
        calculator.monthlyAverages(from: checkIns)
    }

    func moodDistribution(days: Int) -> [(mood: Mood, count: Int)] {
        calculator.moodDistribution(from: checkIns, days: days)
    }

    func factorCorrelations() -> [FactorCorrelation] {
        calculator.factorCorrelations(from: checkIns)
    }

    func topMoodBooster() -> FactorCorrelation? {
        calculator.topMoodBooster(from: checkIns)
    }

    func averageMood(forBinaryFactor keyPath: KeyPath<CheckInFactors, Bool>) -> (with: Double?, without: Double?) {
        calculator.averageMood(from: checkIns, forBinaryFactor: keyPath)
    }

    // swiftlint:disable:next line_length
    func averageMoodByRange(forFactor keyPath: KeyPath<CheckInFactors, Int>) -> (low: FactorRangeGroup, mid: FactorRangeGroup, high: FactorRangeGroup) {
        calculator.averageMoodByRange(from: checkIns, forFactor: keyPath)
    }

    func bestDayOfWeek(days: Int) -> String? {
        calculator.bestDayOfWeek(from: checkIns, days: days)
    }
}
