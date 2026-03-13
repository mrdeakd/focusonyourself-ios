import Foundation
import Observation

@Observable
final class HistoryViewModel {
    private let profileService: ProfileServiceProtocol

    init(profileService: ProfileServiceProtocol = ServiceContainer.shared.profileService) {
        self.profileService = profileService
    }

    var streakStats: (current: Int, longest: Int) {
        profileService.streakStats()
    }

    var checkInDateStrings: Set<String> {
        Set(profileService.profile.checkIns.map { $0.dateString })
    }

    var calendarMonths: [Date] {
        let cal = Calendar.current
        let today = Date()

        let startDate = profileService.earliestCheckInDate ?? today

        var comps = cal.dateComponents([.year, .month], from: startDate)
        comps.day = 1
        guard let startOfStartMonth = cal.date(from: comps) else { return [today] }

        var todayComps = cal.dateComponents([.year, .month], from: today)
        todayComps.day = 1
        guard let startOfCurrentMonth = cal.date(from: todayComps) else { return [today] }

        var months: [Date] = []
        var current = startOfStartMonth
        while current <= startOfCurrentMonth {
            months.append(current)
            guard let next = cal.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }

        return months.reversed()
    }
}
