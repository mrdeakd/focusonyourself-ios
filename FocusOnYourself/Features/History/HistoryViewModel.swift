import Factory
import Foundation
import Observation

@Observable @MainActor
final class HistoryViewModel {
    @ObservationIgnored @Injected(\.checkInUseCase) private var checkInUseCase

    // MARK: - State

    var selectedCheckIn: CheckIn?

    // MARK: - Computed

    var streakStats: (current: Int, longest: Int) {
        !checkInUseCase.allCheckIns.isEmpty ? checkInUseCase.streakStats() : (0, 0)
    }

    var checkInDateStrings: Set<String> {
        Set(checkInUseCase.allCheckIns.map { $0.dateString })
    }

    var calendarMonths: [Date] {
        let cal = Calendar.current
        let today = Date.now
        let startDate = checkInUseCase.earliestCheckInDate ?? today
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

    // MARK: - Public methods

    func checkIn(for dateString: String) -> CheckIn? {
        checkInUseCase.checkIn(for: dateString)
    }

    func selectDay(_ dateString: String) {
        selectedCheckIn = checkIn(for: dateString)
    }
}
