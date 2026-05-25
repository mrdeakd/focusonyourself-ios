import Factory
import Foundation
import Observation
import SwiftUI

@Observable @MainActor
final class InsightsViewModel {
    @ObservationIgnored @Injected(\.checkInUseCase) private var checkInUseCase
    @ObservationIgnored @Injected(\.purchaseUseCase) private var purchaseUseCase

    private let calculator = InsightsCalculator()

    // MARK: - State

    var showingPaywall = false
    var selectedFactor: FactorCorrelation?

    // MARK: - Computed

    var isPro: Bool { purchaseUseCase.isPro }

    private var checkIns: [CheckIn] { checkInUseCase.allCheckIns }

    // MARK: - Public methods

    func recentCheckIns(days: Int) -> [CheckIn] { calculator.recentCheckIns(from: checkIns, days: days) }
    func checkInCount(days: Int) -> Int { calculator.checkInCount(from: checkIns, days: days) }
    func averageMood(days: Int) -> Mood? { calculator.averageMood(from: checkIns, days: days) }
    func averageMoodText(days: Int) -> String { calculator.averageMoodText(from: checkIns, days: days) }
    func dailyMoodData(days: Int) -> [(label: String, checkIn: CheckIn?)] {
        calculator.dailyMoodData(from: checkIns, days: days)
    }
    func weeklyAverages() -> [(week: String, avg: Double)] { calculator.weeklyAverages(from: checkIns) }
    func monthlyAverages() -> [(month: String, avg: Double)] { calculator.monthlyAverages(from: checkIns) }
    func moodDistribution(days: Int) -> [(mood: Mood, count: Int)] {
        calculator.moodDistribution(from: checkIns, days: days)
    }
    func factorCorrelations() -> [FactorCorrelation] { calculator.factorCorrelations(from: checkIns) }
    func topMoodBooster() -> FactorCorrelation? { calculator.topMoodBooster(from: checkIns) }
    func averageMood(forBinaryFactor keyPath: KeyPath<CheckInFactors, Bool>) -> (with: Double?, without: Double?) {
        calculator.averageMood(from: checkIns, forBinaryFactor: keyPath)
    }
    // swiftlint:disable:next line_length
    func averageMoodByRange(forFactor keyPath: KeyPath<CheckInFactors, Int>) -> (low: FactorRangeGroup, mid: FactorRangeGroup, high: FactorRangeGroup) {
        calculator.averageMoodByRange(from: checkIns, forFactor: keyPath)
    }
    func bestDayOfWeek(days: Int) -> String? { calculator.bestDayOfWeek(from: checkIns, days: days) }

    func barColor(for mood: Mood?) -> Color {
        guard let mood else { return Color.foyBorder }
        switch mood {
        case .great: return Color.foyOrange
        case .good:  return Color.foyOrangeAccent
        case .okay:  return Color.foyForegroundSecondary
        case .low:   return Color.foyPlaceholder
        case .rough: return Color.foyBorder
        }
    }

    func avgBarColor(for avg: Double) -> Color {
        switch Int(avg.rounded()) {
        case 5: return Color.foyOrange
        case 4: return Color.foyOrangeAccent
        case 3: return Color.foyForegroundSecondary
        case 2: return Color.foyPlaceholder
        default: return Color.foyBorder
        }
    }
}
