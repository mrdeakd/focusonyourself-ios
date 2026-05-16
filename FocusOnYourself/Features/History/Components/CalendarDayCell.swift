import SwiftUI

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
        .overlay {
            if state == .today {
                Circle().stroke(Color.foyNavy, lineWidth: borderWidth)
            }
        }
    }

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
