import Foundation

// Model types duplicated for the widget extension (shared via App Group UserDefaults JSON)

enum WidgetMood: String, Codable {
    case rough, low, okay, good, great

    var emoji: String {
        switch self {
        case .rough: return "😩"
        case .low:   return "😔"
        case .okay:  return "😐"
        case .good:  return "😊"
        case .great: return "🤩"
        }
    }

    var displayName: String {
        switch self {
        case .rough: return String(localized: "mood.rough", bundle: .main)
        case .low:   return String(localized: "mood.low", bundle: .main)
        case .okay:  return String(localized: "mood.okay", bundle: .main)
        case .good:  return String(localized: "mood.good", bundle: .main)
        case .great: return String(localized: "mood.great", bundle: .main)
        }
    }

    var imageName: String {
        "mood-\(rawValue)"
    }
}

private struct WidgetCheckIn: Codable {
    let dateString: String
    let mood: WidgetMood
    let feelingsDescription: String?

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    var date: Date { Self.formatter.date(from: dateString) ?? .distantPast }
}

private struct WidgetUserProfile: Codable {
    var checkIns: [WidgetCheckIn] = []
}

struct WidgetDataProvider {
    private static let profileKey = "userProfile"
    private static let suiteName = "group.app.ddworks.FocusOnYourself"

    private static func loadProfile() -> WidgetUserProfile {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: profileKey),
            let profile = try? JSONDecoder().decode(WidgetUserProfile.self, from: data)
        else { return WidgetUserProfile() }
        return profile
    }

    static func streakStats() -> (current: Int, longest: Int) {
        let profile = loadProfile()
        let cal = Calendar.current
        let checkInDates = Set(profile.checkIns.map { cal.startOfDay(for: $0.date) })

        var current = 0
        var day = cal.startOfDay(for: Date())
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
            if let prevDate = prev,
               let expected = cal.date(byAdding: .day, value: 1, to: prevDate),
               expected == checkInDate {
                run += 1
            } else {
                run = 1
            }
            if run > longest { longest = run }
            prev = checkInDate
        }

        return (current: current, longest: longest)
    }

    static var todaysMood: WidgetMood? {
        let profile = loadProfile()
        let ds = todayDateString()
        return profile.checkIns.first { $0.dateString == ds }?.mood
    }

    static var hasCheckedInToday: Bool {
        let profile = loadProfile()
        return profile.checkIns.contains { $0.dateString == todayDateString() }
    }

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}
