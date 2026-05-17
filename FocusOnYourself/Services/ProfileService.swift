import Factory
import Foundation
import Observation
import WidgetKit

private struct PendingWidgetCheckIn: Codable {
    let moodRawValue: String
    let dateString: String
    let timestamp: Date
}

@Observable
final class ProfileService: ProfileServiceProtocol {
    private(set) var profile: UserProfile

    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService
    private var externalChangeObserver: NSObjectProtocol?

    init() {
        self.profile = UserProfile()
        if let data = userDefaultsService.getData(.userProfile) {
            do {
                self.profile = try JSONDecoder().decode(UserProfile.self, from: data)
            } catch {
                assertionFailure("Failed to decode UserProfile: \(error)")
            }
        }
        observeExternalChanges()
    }

    private func observeExternalChanges() {
        externalChangeObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.reloadProfile()
        }
    }

    private func reloadProfile() {
        guard let data = userDefaultsService.getData(.userProfile) else { return }
        do {
            self.profile = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            assertionFailure("Failed to decode UserProfile from external change: \(error)")
        }
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        do {
            let data = try JSONEncoder().encode(profile)
            userDefaultsService.setData(.userProfile, value: data)
        } catch {
            assertionFailure("Failed to encode UserProfile: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func recordCheckIn(mood: Mood, feelingsDescription: String?, factors: CheckInFactors? = nil) {
        let dateString = CheckIn.dateString(for: Date.now)
        var updatedProfile = profile
        let entry = CheckIn(dateString: dateString, mood: mood, feelingsDescription: feelingsDescription, factors: factors)
        if let idx = updatedProfile.checkIns.firstIndex(where: { $0.dateString == dateString }) {
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
        var day = cal.startOfDay(for: Date.now)
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
        let dateString = CheckIn.dateString(for: Date.now)
        return profile.checkIns.contains { $0.dateString == dateString }
    }

    var todaysMood: Mood? {
        let dateString = CheckIn.dateString(for: Date.now)
        return profile.checkIns.first { $0.dateString == dateString }?.mood
    }

    var todaysFeelingsDescription: String? {
        let dateString = CheckIn.dateString(for: Date.now)
        return profile.checkIns.first { $0.dateString == dateString }?.feelingsDescription
    }

    var earliestCheckInDate: Date? {
        profile.checkIns.map { $0.date }.min()
    }

    var todaysFactors: CheckInFactors? {
        let dateString = CheckIn.dateString(for: Date.now)
        return profile.checkIns.first { $0.dateString == dateString }?.factors
    }

    func resetAllData() {
        userDefaultsService.setData(.userProfile, value: nil)
        userDefaultsService.setData(.affirmationCache, value: nil)
        userDefaultsService.setData(.affirmationCacheDate, value: nil)
        profile = UserProfile()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func mergeWidgetCheckIn() {
        guard let raw = userDefaultsService.getLocalData(.pendingWidgetCheckIn) else { return }
        guard let pending = try? JSONDecoder().decode(PendingWidgetCheckIn.self, from: raw) else {
            userDefaultsService.clearLocalData(.pendingWidgetCheckIn)
            return
        }
        let existingCheckIn = profile.checkIns.first { $0.dateString == pending.dateString }
        let shouldApply = existingCheckIn == nil || pending.timestamp > existingCheckIn!.date
        if shouldApply, let mood = Mood(rawValue: pending.moodRawValue) {
            recordCheckIn(mood: mood, feelingsDescription: nil)
        }
        userDefaultsService.clearLocalData(.pendingWidgetCheckIn)
    }

    var streakStartDate: Date? {
        let cal = Calendar.current
        let checkInDates = Set(profile.checkIns.map { cal.startOfDay(for: $0.date) })
        var day = cal.startOfDay(for: Date.now)
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
