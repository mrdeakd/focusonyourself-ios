import Factory
import Foundation
import Observation

@Observable @MainActor
final class HistoryViewModel {
    @ObservationIgnored @Injected(\.profileService) private var profileService

    var streakStats: (current: Int, longest: Int) {
        profileService.streakStats()
    }

    var checkInDateStrings: Set<String> {
        Set(profileService.profile.checkIns.map { $0.dateString })
    }

    var selectedCheckIn: CheckIn?

    func checkIn(for dateString: String) -> CheckIn? {
        profileService.profile.checkIns.first { $0.dateString == dateString }
    }

    func selectDay(_ dateString: String) {
        selectedCheckIn = checkIn(for: dateString)
    }

    var calendarMonths: [Date] {
        let cal = Calendar.current
        let today = Date.now

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
