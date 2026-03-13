import Foundation

extension Date {
    var homeScreenFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: self)
    }
}
