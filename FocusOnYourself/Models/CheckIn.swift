import Foundation

struct CheckIn: Codable, Equatable, Identifiable {
    var id: String { dateString }
    let dateString: String   // "yyyy-MM-dd"
    let mood: Mood
    let feelingsDescription: String?

    var date: Date { Self.formatter.date(from: dateString) ?? .distantPast }

    static func dateString(for date: Date) -> String {
        formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
