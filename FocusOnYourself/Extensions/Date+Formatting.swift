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

    var homeScreenFormatted: String {
        Date.homeScreenFormatter.string(from: self)
    }

    var calendarMonthFormatted: String {
        Date.calendarMonthFormatter.string(from: self)
    }
}
