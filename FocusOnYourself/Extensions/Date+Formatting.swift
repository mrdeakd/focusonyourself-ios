import Foundation

extension Date {
    private static let homeScreenFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    private static let calendarMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let dayOfWeekAbbreviatedFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let weekStartFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let monthAbbreviatedFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    private static let dayOfWeekFullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
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
