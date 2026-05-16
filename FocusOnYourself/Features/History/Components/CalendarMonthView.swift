import SwiftUI

struct CalendarMonthView: View {
    let month: Date
    let checkInDates: Set<String>
    var onDayTapped: ((String) -> Void)?

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(monthTitle)
                .font(.foyBodyMedium)
                .foregroundStyle(Color.foyForeground)

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(dayLabels[index])
                        .font(.foySectionLabel)
                        .foregroundStyle(Color.foyPlaceholder)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: Spacing.xs) {
                ForEach(cellRows, id: \.first?.offset) { row in
                    HStack(spacing: 0) {
                        ForEach(row, id: \.offset) { cell in
                            CalendarDayCell(day: cell.day, state: cell.state)
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    if cell.state == .streakDay || cell.state == .today, let key = cell.dateKey {
                                        onDayTapped?(key)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    private var cellRows: [[(offset: Int, day: Int, state: DayState, dateKey: String?)]] {
        stride(from: 0, to: cells.count, by: 7).map { offset in
            Array(cells[offset..<min(offset + 7, cells.count)])
        }
    }

    private var monthTitle: String {
        month.calendarMonthFormatted
    }

    private var cells: [(offset: Int, day: Int, state: DayState, dateKey: String?)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date.now)

        let comps = cal.dateComponents([.year, .month], from: month)
        guard let firstDay = cal.date(from: comps) else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstDay) - 1

        guard let range = cal.range(of: .day, in: .month, for: firstDay) else { return [] }
        let daysInMonth = range.count

        var result: [(offset: Int, day: Int, state: DayState, dateKey: String?)] = []

        for index in 0..<firstWeekday {
            result.append((offset: index, day: 0, state: .empty, dateKey: nil))
        }

        for day in 1...daysInMonth {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: firstDay) else { continue }
            let dateKey = CheckIn.dateString(for: date)
            let isToday = date == today
            let isPast = date < today
            let hasCheckIn = checkInDates.contains(dateKey)

            let state: DayState
            if isToday {
                state = .today
            } else if isPast {
                state = hasCheckIn ? .streakDay : .skipped
            } else {
                state = .future
            }

            result.append((offset: firstWeekday + day - 1, day: day, state: state, dateKey: dateKey))
        }

        let totalCells = result.count
        let remainder = totalCells % 7
        if remainder != 0 {
            let trailingCount = 7 - remainder
            for index in 0..<trailingCount {
                result.append((offset: totalCells + index, day: 0, state: .empty, dateKey: nil))
            }
        }

        return result
    }
}
