import Foundation
import Observation

@Observable
final class AppState {
    var profile: UserProfile

    init() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = saved
        } else {
            self.profile = UserProfile()
        }
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }

    func recordCheckIn(mood: Mood) {
        let ds = CheckIn.dateString(for: Date())
        var updatedProfile = profile
        if let idx = updatedProfile.checkIns.firstIndex(where: { $0.dateString == ds }) {
            updatedProfile.checkIns[idx] = CheckIn(dateString: ds, mood: mood)
        } else {
            updatedProfile.checkIns.append(CheckIn(dateString: ds, mood: mood))
        }
        updateProfile(updatedProfile)
    }

    func streakStats() -> (current: Int, longest: Int) {
        let cal = Calendar.current
        let checkInDates = Set(profile.checkIns.map { cal.startOfDay(for: $0.date) })

        // Current streak: walk backward from today
        var current = 0
        var day = cal.startOfDay(for: Date())
        // If today has no check-in, try from yesterday
        if !checkInDates.contains(day) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while checkInDates.contains(day) {
            current += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }

        // Longest streak: walk sorted dates for longest consecutive run
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

    var streakStartDate: Date? {
        let cal = Calendar.current
        let checkInDates = Set(profile.checkIns.map { cal.startOfDay(for: $0.date) })
        var day = cal.startOfDay(for: Date())
        if !checkInDates.contains(day) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var start: Date? = nil
        while checkInDates.contains(day) {
            start = day
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return start
    }
}
