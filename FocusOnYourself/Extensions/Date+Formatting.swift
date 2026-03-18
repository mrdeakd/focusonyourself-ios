import Foundation

extension Date {
    private static let homeScreenFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private static let calendarMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let dayOfWeekAbbreviatedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let weekStartFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let monthAbbreviatedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let dayOfWeekFullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    var homeScreenFormatted: String {
        Date.homeScreenFormatter.string(from: self)
    }

    var calendarMonthFormatted: String {
        Date.calendarMonthFormatter.string(from: self)
    }

    var dayOfWeekAbbreviated: String {
        Date.dayOfWeekAbbreviatedFormatter.string(from: self)
    }

    var weekStart: String {
        Date.weekStartFormatter.string(from: self)
    }

    var monthAbbreviated: String {
        Date.monthAbbreviatedFormatter.string(from: self)
    }

    var dayOfWeekFull: String {
        Date.dayOfWeekFullFormatter.string(from: self)
    }
}
