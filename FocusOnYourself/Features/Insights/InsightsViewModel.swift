import Factory
import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class InsightsViewModel {
    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.purchaseService) private var purchaseService

    var isPro: Bool { purchaseService.isPro }
    var showingPaywall = false
    var selectedFactor: FactorCorrelation?

    func recentCheckIns(days: Int) -> [CheckIn] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: Date.now)) ?? Date.now
        return profileService.profile.checkIns.filter { $0.date >= cutoff }
    }

    func checkInCount(days: Int) -> Int {
        recentCheckIns(days: days).count
    }

    func averageMood(days: Int) -> Mood? {
        let checkIns = recentCheckIns(days: days)
        guard let avg = averageMoodDouble(from: checkIns) else { return nil }
        return Mood.allCases.first { $0.numericValue == Int(avg.rounded()) }
    }

    func averageMoodText(days: Int) -> String {
        let checkIns = recentCheckIns(days: days)
        guard let avg = averageMoodDouble(from: checkIns) else { return "—" }
        let rounded = Int(avg.rounded())
        return Mood.allCases.first { $0.numericValue == rounded }?.displayName ?? "—"
    }

    // Returns the last `days` calendar days as (label, mood?) pairs
    func dailyMoodData(days: Int) -> [(label: String, checkIn: CheckIn?)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date.now)

        return (0..<days).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let dateString = CheckIn.dateString(for: date)
            let checkIn = profileService.profile.checkIns.first { $0.dateString == dateString }
            return (label: date.dayOfWeekAbbreviated, checkIn: checkIn)
        }
    }

    // Groups check-ins into the last 4 ISO weeks; returns (weekLabel, averageMoodValue)
    func weeklyAverages() -> [(week: String, avg: Double)] {
        let cal = Calendar.current
        let today = Date.now

        return (0..<4).reversed().map { weekOffset in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                let weekInterval = cal.dateInterval(of: .weekOfYear, for: weekStart) else {
                return (week: "W?", avg: 0)
            }
            let checkIns = profileService.profile.checkIns.filter { checkIn in
                weekInterval.contains(checkIn.date)
            }
            let avg = averageMoodDouble(from: checkIns) ?? 0.0
            return (week: weekInterval.start.weekStart, avg: avg)
        }
    }

    func monthlyAverages() -> [(month: String, avg: Double)] {
        let cal = Calendar.current
        let today = Date.now

        return (0..<6).reversed().map { offset in
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: today),
                let monthInterval = cal.dateInterval(of: .month, for: monthDate) else {
                return (month: "?", avg: 0)
            }
            let checkIns = profileService.profile.checkIns.filter { checkIn in
                monthInterval.contains(checkIn.date)
            }
            let avg = averageMoodDouble(from: checkIns) ?? 0.0
            return (month: monthInterval.start.monthAbbreviated, avg: avg)
        }
    }

    func moodDistribution(days: Int) -> [(mood: Mood, count: Int)] {
        let checkIns = recentCheckIns(days: days)
        return Mood.allCases.reversed().map { mood in
            (mood: mood, count: checkIns.filter { $0.mood == mood }.count)
        }
    }

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

    private func averageMoodDouble(from checkIns: [CheckIn]) -> Double? {
        guard !checkIns.isEmpty else { return nil }
        return Double(checkIns.map { $0.mood.numericValue }.reduce(0, +)) / Double(checkIns.count)
    }

    // MARK: - Factor Correlation

    struct FactorCorrelation: Identifiable {
        let id: String
        let factor: String
        let pearsonR: Double
        var directionLabel: String { pearsonR >= 0 ? "↑ mood" : "↓ mood" }
    }

    private static let factorMinimum = 10

    var factorCheckIns: [CheckIn] {
        profileService.profile.checkIns.filter { $0.factors != nil }
    }

    func factorCorrelations() -> [FactorCorrelation] {
        let entries = factorCheckIns
        guard entries.count >= Self.factorMinimum else { return [] }
        let moods = entries.map { Double($0.mood.numericValue) }
        var results: [FactorCorrelation] = []
        if let corr = Self.pearsonCorrelation(entries.map { Double($0.factors!.sleepQuality) }, moods) {
            results.append(FactorCorrelation(id: "sleep", factor: "Sleep Quality", pearsonR: corr))
        }
        if let corr = Self.pearsonCorrelation(entries.map { Double($0.factors!.stressLevel) }, moods) {
            results.append(FactorCorrelation(id: "stress", factor: "Stress Level", pearsonR: corr))
        }
        if let corr = Self.pearsonCorrelation(entries.map { $0.factors!.exercised ? 1.0 : 0.0 }, moods) {
            results.append(FactorCorrelation(id: "exercise", factor: "Exercise", pearsonR: corr))
        }
        if let corr = Self.pearsonCorrelation(entries.map { Double($0.factors!.socialQuality) }, moods) {
            results.append(FactorCorrelation(id: "social", factor: "Social Quality", pearsonR: corr))
        }
        return results.sorted { abs($0.pearsonR) > abs($1.pearsonR) }
    }

    func topMoodBooster() -> FactorCorrelation? {
        factorCorrelations().first
    }

    func averageMood(forBinaryFactor keyPath: KeyPath<CheckInFactors, Bool>) -> (with: Double?, without: Double?) {
        let entries = factorCheckIns.compactMap { checkIn -> (mood: Int, flag: Bool)? in
            guard let factors = checkIn.factors else { return nil }
            return (checkIn.mood.numericValue, factors[keyPath: keyPath])
        }
        let withMoods = entries.filter { $0.flag }.map { Double($0.mood) }
        let withoutMoods = entries.filter { !$0.flag }.map { Double($0.mood) }
        let avg: ([Double]) -> Double? = { arr in arr.isEmpty ? nil : arr.reduce(0, +) / Double(arr.count) }
        return (avg(withMoods), avg(withoutMoods))
    }

    struct FactorRangeGroup {
        let label: String
        let average: Double?
        let count: Int
    }

    // swiftlint:disable:next line_length
    func averageMoodByRange(forFactor keyPath: KeyPath<CheckInFactors, Int>) -> (low: FactorRangeGroup, mid: FactorRangeGroup, high: FactorRangeGroup) {
        let entries = factorCheckIns.compactMap { checkIn -> (mood: Int, value: Int)? in
            guard let factors = checkIn.factors else { return nil }
            return (checkIn.mood.numericValue, factors[keyPath: keyPath])
        }
        func group(_ predicate: (Int) -> Bool) -> FactorRangeGroup {
            let matched = entries.filter { predicate($0.value) }
            let avg: Double? = matched.isEmpty ? nil : Double(matched.map(\.mood).reduce(0, +)) / Double(matched.count)
            return FactorRangeGroup(label: "", average: avg, count: matched.count)
        }
        return (
            low:  group { $0 <= 2 },
            mid:  group { $0 == 3 },
            high: group { $0 >= 4 }
        )
    }

    private static func pearsonCorrelation(_ xs: [Double], _ ys: [Double]) -> Double? {
        guard xs.count == ys.count, xs.count > 1 else { return nil }
        let count = Double(xs.count)
        let meanX = xs.reduce(0, +) / count
        let meanY = ys.reduce(0, +) / count
        let numerator = zip(xs, ys).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +)
        let denomX = sqrt(xs.map { pow($0 - meanX, 2) }.reduce(0, +))
        let denomY = sqrt(ys.map { pow($0 - meanY, 2) }.reduce(0, +))
        guard denomX > 0, denomY > 0 else { return nil }
        return numerator / (denomX * denomY)
    }

    // Best day of week by average mood over `days` days (Pro feature)
    func bestDayOfWeek(days: Int) -> String? {
        let checkIns = recentCheckIns(days: days)
        guard !checkIns.isEmpty else { return nil }
        let cal = Calendar.current

        var byWeekday: [Int: [Int]] = [:]
        for checkIn in checkIns {
            let weekday = cal.component(.weekday, from: checkIn.date)
            byWeekday[weekday, default: []].append(checkIn.mood.numericValue)
        }
        guard let best = byWeekday.max(by: { dayA, dayB in
            let avgA = Double(dayA.value.reduce(0, +)) / Double(dayA.value.count)
            let avgB = Double(dayB.value.reduce(0, +)) / Double(dayB.value.count)
            return avgA < avgB
        }) else { return nil }

        let date = cal.date(bySetting: .weekday, value: best.key, of: Date.now) ?? Date.now
        return date.dayOfWeekFull
    }
}
