import Factory
import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class InsightsViewModel {
    @ObservationIgnored @Injected(\.insightsUseCase) private var insightsUseCase
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService

    var isPro: Bool { purchaseService.isPro }
    var showingPaywall = false
    var selectedFactor: FactorCorrelation?

    func recentCheckIns(days: Int) -> [CheckIn] { insightsUseCase.recentCheckIns(days: days) }
    func checkInCount(days: Int) -> Int { insightsUseCase.checkInCount(days: days) }
    func averageMood(days: Int) -> Mood? { insightsUseCase.averageMood(days: days) }
    func averageMoodText(days: Int) -> String { insightsUseCase.averageMoodText(days: days) }
    func dailyMoodData(days: Int) -> [(label: String, checkIn: CheckIn?)] { insightsUseCase.dailyMoodData(days: days) }
    func weeklyAverages() -> [(week: String, avg: Double)] { insightsUseCase.weeklyAverages() }
    func monthlyAverages() -> [(month: String, avg: Double)] { insightsUseCase.monthlyAverages() }
    func moodDistribution(days: Int) -> [(mood: Mood, count: Int)] { insightsUseCase.moodDistribution(days: days) }
    func factorCorrelations() -> [FactorCorrelation] { insightsUseCase.factorCorrelations() }
    func topMoodBooster() -> FactorCorrelation? { insightsUseCase.topMoodBooster() }
    func averageMood(forBinaryFactor keyPath: KeyPath<CheckInFactors, Bool>) -> (with: Double?, without: Double?) {
        insightsUseCase.averageMood(forBinaryFactor: keyPath)
    }
    // swiftlint:disable:next line_length
    func averageMoodByRange(forFactor keyPath: KeyPath<CheckInFactors, Int>) -> (low: FactorRangeGroup, mid: FactorRangeGroup, high: FactorRangeGroup) {
        insightsUseCase.averageMoodByRange(forFactor: keyPath)
    }
    func bestDayOfWeek(days: Int) -> String? { insightsUseCase.bestDayOfWeek(days: days) }

    // MARK: - UI Helpers

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
