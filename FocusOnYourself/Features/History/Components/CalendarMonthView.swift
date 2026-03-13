import SwiftUI

private enum DayState {
    case streakDay      // checked in
    case skipped        // past, no check-in
    case today          // today (no check-in or not)
    case future         // future date
    case empty          // leading/trailing filler cell
}

private struct CalendarDayCell: View {
    let day: Int      // 1-31, or 0 for empty
    let state: DayState

    private let cellSize: CGFloat = 32
    private let borderWidth: CGFloat = 1.5
    var body: some View {
        ZStack {
            cellBackground
            if day > 0 && state != .future && state != .empty {
                Text("\(day)")
                    .font(.foyHintMedium)
                    .foregroundStyle(textColor)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .clipShape(Circle())
        .overlay(
            Group {
                if state == .today {
                    Circle().stroke(Color.foyNavy, lineWidth: borderWidth)
                }
            }
        )
    }

    @ViewBuilder
    private var cellBackground: some View {
        switch state {
        case .streakDay: Color.foyNavy
        case .skipped:   Color.foyCalendarSkipped
        case .today:     Color.white
        default:         Color.clear
        }
    }

    private var textColor: Color {
        switch state {
        case .streakDay: return .white
        case .skipped:   return Color.foyPlaceholder
        case .today:     return Color.foyForeground
        default:         return Color.clear
        }
    }
}

struct CalendarMonthView: View {
    let month: Date          // any date in the target month
    let checkInDates: Set<String>  // set of "yyyy-MM-dd" strings

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Month header: "March 2026"
            Text(monthTitle)
                .font(.foyBodyMedium)
                .foregroundStyle(Color.foyForeground)

            // Day-of-week row
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.foySectionLabel)
                        .foregroundStyle(Color.foyPlaceholder)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(cells, id: \.offset) { cell in
                    CalendarDayCell(day: cell.day, state: cell.state)
                }
            }
        }
    }

    // MARK: - Computed

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    private var cells: [(offset: Int, day: Int, state: DayState)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // First day of month
        let comps = cal.dateComponents([.year, .month], from: month)
        guard let firstDay = cal.date(from: comps) else { return [] }

        // Leading empty cells (weekday of first day, 0=Sun)
        let firstWeekday = cal.component(.weekday, from: firstDay) - 1  // 0-indexed

        // Days in month
        let range = cal.range(of: .day, in: .month, for: firstDay)!
        let daysInMonth = range.count

        var result: [(offset: Int, day: Int, state: DayState)] = []

        // Leading empties
        for i in 0..<firstWeekday {
            result.append((offset: i, day: 0, state: .empty))
        }

        // Day cells
        for d in 1...daysInMonth {
            guard let date = cal.date(byAdding: .day, value: d - 1, to: firstDay) else { continue }
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

            result.append((offset: firstWeekday + d - 1, day: d, state: state))
        }

        // Trailing empties to complete the grid (must be multiple of 7)
        let totalCells = result.count
        let remainder = totalCells % 7
        if remainder != 0 {
            let trailingCount = 7 - remainder
            for i in 0..<trailingCount {
                result.append((offset: totalCells + i, day: 0, state: .empty))
            }
        }

        return result
    }
}
