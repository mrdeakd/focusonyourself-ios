import Foundation
import Observation

@Observable
final class HistoryViewModel {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var streakStats: (current: Int, longest: Int) {
        appState.streakStats()
    }

    var checkInDateStrings: Set<String> {
        Set(appState.profile.checkIns.map { $0.dateString })
    }

    var calendarMonths: [Date] {
        let cal = Calendar.current
        let today = Date()

        let startDate = appState.streakStartDate ?? today

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

        return months
    }
}
