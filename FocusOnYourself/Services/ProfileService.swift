import Factory
import Foundation
import Observation
import WidgetKit

@Observable
final class ProfileService: ProfileServiceProtocol {
    private(set) var profile: UserProfile

    private let userDefaultsService: UserDefaultsServiceProtocol

    init(userDefaultsService: UserDefaultsServiceProtocol = Container.shared.userDefaultsService()) {
        self.userDefaultsService = userDefaultsService
        if let data = userDefaultsService.getData(.userProfile),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = saved
        } else {
            self.profile = UserProfile()
        }
        observeExternalChanges()
    }

    private func observeExternalChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.reloadProfile()
        }
    }

    private func reloadProfile() {
        guard
            let data = userDefaultsService.getData(.userProfile),
            let saved = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return }
        self.profile = saved
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            userDefaultsService.setData(.userProfile, value: data)
        }
    }

    func recordCheckIn(mood: Mood, feelingsDescription: String?) {
        let ds = CheckIn.dateString(for: Date())
        var updatedProfile = profile
        let entry = CheckIn(dateString: ds, mood: mood, feelingsDescription: feelingsDescription)
        if let idx = updatedProfile.checkIns.firstIndex(where: { $0.dateString == ds }) {
            updatedProfile.checkIns[idx] = entry
        } else {
            updatedProfile.checkIns.append(entry)
        }
        updateProfile(updatedProfile)
        WidgetCenter.shared.reloadAllTimelines()
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

    var hasCheckedInToday: Bool {
        let ds = CheckIn.dateString(for: Date())
        return profile.checkIns.contains { $0.dateString == ds }
    }

    var todaysMood: Mood? {
        let ds = CheckIn.dateString(for: Date())
        return profile.checkIns.first { $0.dateString == ds }?.mood
    }

    var todaysFeelingsDescription: String? {
        let ds = CheckIn.dateString(for: Date())
        return profile.checkIns.first { $0.dateString == ds }?.feelingsDescription
    }

    var earliestCheckInDate: Date? {
        profile.checkIns.map { $0.date }.min()
    }

    var streakStartDate: Date? {
        let cal = Calendar.current
        let checkInDates = Set(profile.checkIns.map { cal.startOfDay(for: $0.date) })
        var day = cal.startOfDay(for: Date())
        if !checkInDates.contains(day) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var start: Date?
        while checkInDates.contains(day) {
            start = day
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return start
    }
}
