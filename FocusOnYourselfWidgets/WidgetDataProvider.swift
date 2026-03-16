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
        case .rough: return "Rough"
        case .low:   return "Low"
        case .okay:  return "Okay"
        case .good:  return "Good"
        case .great: return "Great"
        }
    }
}

private struct WidgetCheckIn: Codable {
    let dateString: String
    let mood: WidgetMood
    let feelingsDescription: String?

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
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
        var prev: Date? = nil
        for d in sorted {
            if let p = prev, let expected = cal.date(byAdding: .day, value: 1, to: p), expected == d {
                run += 1
            } else {
                run = 1
            }
            if run > longest { longest = run }
            prev = d
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
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
}
