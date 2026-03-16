import Foundation
import Observation

@Observable
@MainActor
final class InsightsViewModel {
    private let profileService: ProfileService
    private let purchaseService: PurchaseService

    init(
        profileService: ProfileService = ServiceContainer.shared.profileService,
        purchaseService: PurchaseService = ServiceContainer.shared.purchaseService
    ) {
        self.profileService = profileService
        self.purchaseService = purchaseService
    }

    var isPro: Bool { purchaseService.isPro }

    func recentCheckIns(days: Int) -> [CheckIn] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: Date())) ?? Date()
        return profileService.profile.checkIns.filter { $0.date >= cutoff }
    }

    func checkInCount(days: Int) -> Int {
        recentCheckIns(days: days).count
    }

    func averageMoodEmoji(days: Int) -> String {
        let checkIns = recentCheckIns(days: days)
        guard !checkIns.isEmpty else { return "—" }
        let avg = Double(checkIns.map { $0.mood.numericValue }.reduce(0, +)) / Double(checkIns.count)
        let rounded = Int(avg.rounded())
        return Mood.allCases.first { $0.numericValue == rounded }?.emoji ?? "😐"
    }

    // Returns the last `days` calendar days as (label, mood?) pairs
    func dailyMoodData(days: Int) -> [(label: String, checkIn: CheckIn?)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<days).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let ds = CheckIn.dateString(for: date)
            let checkIn = profileService.profile.checkIns.first { $0.dateString == ds }
            return (label: formatter.string(from: date), checkIn: checkIn)
        }
    }

    // Groups check-ins into the last 4 ISO weeks; returns (weekLabel, averageMoodValue)
    func weeklyAverages() -> [(week: String, avg: Double)] {
        let cal = Calendar.current
        let today = Date()

        return (0..<4).reversed().map { weekOffset in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                  let weekInterval = cal.dateInterval(of: .weekOfYear, for: weekStart) else {
                return (week: "W?", avg: 0)
            }
            let checkIns = profileService.profile.checkIns.filter {
                weekInterval.contains($0.date)
            }
            let avg = checkIns.isEmpty
                ? 0.0
                : Double(checkIns.map { $0.mood.numericValue }.reduce(0, +)) / Double(checkIns.count)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let label = formatter.string(from: weekInterval.start)
            return (week: label, avg: avg)
        }
    }

    // Best day of week by average mood over `days` days (Pro feature)
    func bestDayOfWeek(days: Int) -> String? {
        let checkIns = recentCheckIns(days: days)
        guard !checkIns.isEmpty else { return nil }
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        var byWeekday: [Int: [Int]] = [:]
        for ci in checkIns {
            let weekday = cal.component(.weekday, from: ci.date)
            byWeekday[weekday, default: []].append(ci.mood.numericValue)
        }
        guard let best = byWeekday.max(by: {
            let avgA = Double($0.value.reduce(0, +)) / Double($0.value.count)
            let avgB = Double($1.value.reduce(0, +)) / Double($1.value.count)
            return avgA < avgB
        }) else { return nil }

        let date = cal.date(bySetting: .weekday, value: best.key, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
