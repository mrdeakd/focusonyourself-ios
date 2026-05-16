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

    var imageName: String {
        "mood-\(rawValue)"
    }
}

struct WidgetCheckInFactors: Codable {
    let sleepQuality: Int
    let stressLevel: Int
    let exercised: Bool
    let socialQuality: Int
}

private struct WidgetCheckIn: Codable {
    let dateString: String
    let mood: WidgetMood
    let feelingsDescription: String?
    let factors: WidgetCheckInFactors?

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
    var onboardingCompleted = false
}

private struct WidgetPendingCheckIn: Codable {
    let moodRawValue: String
    let dateString: String
    let timestamp: Date
}

enum WidgetDataProvider {
    private static let profileKey = "userProfile"
    private static let pendingCheckInKey = "pendingWidgetCheckIn"
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
        let dateString = todayDateString()
        return profile.checkIns.first { $0.dateString == dateString }?.mood
    }

    static var hasCheckedInToday: Bool {
        let profile = loadProfile()
        return profile.checkIns.contains { $0.dateString == todayDateString() }
    }

    static func logMood(_ rawValue: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        var profile = loadProfile()
        let today = todayDateString()
        let mood = WidgetMood(rawValue: rawValue) ?? .okay
        let entry = WidgetCheckIn(dateString: today, mood: mood, feelingsDescription: nil, factors: nil)
        if let idx = profile.checkIns.firstIndex(where: { $0.dateString == today }) {
            profile.checkIns[idx] = entry
        } else {
            profile.checkIns.append(entry)
        }
        if let encoded = try? JSONEncoder().encode(profile) {
            defaults.set(encoded, forKey: profileKey)
        }
        let pending = WidgetPendingCheckIn(moodRawValue: rawValue, dateString: today, timestamp: Date())
        if let pendingData = try? JSONEncoder().encode(pending) {
            defaults.set(pendingData, forKey: pendingCheckInKey)
        }
    }

    static func pendingCheckIn() -> (moodRawValue: String, dateString: String, timestamp: Date)? {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: pendingCheckInKey),
            let pending = try? JSONDecoder().decode(WidgetPendingCheckIn.self, from: data)
        else { return nil }
        return (pending.moodRawValue, pending.dateString, pending.timestamp)
    }

    static func clearPendingCheckIn() {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: pendingCheckInKey)
    }

    static var todaysFactors: WidgetCheckInFactors? {
        let profile = loadProfile()
        let dateString = todayDateString()
        return profile.checkIns.first { $0.dateString == dateString }?.factors
    }

    static var isOnboarded: Bool {
        loadProfile().onboardingCompleted
    }

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}
