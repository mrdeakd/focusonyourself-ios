import SwiftUI

enum DayState {
    case streakDay
    case skipped
    case today
    case future
    case empty
}

struct CalendarDayCell: View {
    let day: Int
    let state: DayState

    private let cellSize: CGFloat = 32
    private let borderWidth: CGFloat = 1.5
    var body: some View {
        ZStack {
            cellBackground
            if day > 0 && state != .empty {
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
        case .today:     Color.foyCard
        default:         Color.clear
        }
    }

    private var textColor: Color {
        switch state {
        case .streakDay: return .white
        case .skipped:   return Color.foyPlaceholder
        case .today:     return Color.foyForeground
        case .future:    return Color.foyPlaceholder
        default:         return Color.clear
        }
    }
}
