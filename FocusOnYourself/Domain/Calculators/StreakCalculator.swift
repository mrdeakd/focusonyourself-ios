import Foundation

struct StreakCalculator {
    func compute(checkIns: [CheckIn]) -> (current: Int, longest: Int) {
        let cal = Calendar.current
        let checkInDates = Set(checkIns.map { cal.startOfDay(for: $0.date) })

        var current = 0
        var day = cal.startOfDay(for: Date.now)
        if !checkInDates.contains(day) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while checkInDates.contains(day) {
            current += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }

        let sorted = checkInDates.sorted()
        var longest = 0
        var run = 0
        var prev: Date?
        for checkInDate in sorted {
            let isConsecutive = prev.flatMap { cal.date(byAdding: .day, value: 1, to: $0) } == checkInDate
            if isConsecutive {
                run += 1
            } else {
                run = 1
            }
            if run > longest { longest = run }
            prev = checkInDate
        }

        return (current: current, longest: longest)
    }

    func startDate(checkIns: [CheckIn]) -> Date? {
        let cal = Calendar.current
        let checkInDates = Set(checkIns.map { cal.startOfDay(for: $0.date) })
        var day = cal.startOfDay(for: Date.now)
        if !checkInDates.contains(day) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var start: Date?
        while checkInDates.contains(day) {
            start = day
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return start
    }
}
