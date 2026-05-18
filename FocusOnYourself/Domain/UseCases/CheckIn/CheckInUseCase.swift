import Factory
import Foundation

final class CheckInUseCase: CheckInUseCaseProtocol {
    @Injected(\.profileService) private var profileService
    @Injected(\.checkinsService) private var checkinsService
    @Injected(\.userDefaultsService) private var userDefaultsService
    private let streakCalculator = StreakCalculator()

    func record(mood: Mood, feelingsDescription: String?, factors: CheckInFactors?) async throws {
        let checkIn = CheckIn(
            dateString: CheckIn.dateString(for: .now),
            mood: mood,
            feelingsDescription: feelingsDescription,
            factors: factors
        )
        try await save(checkIn)
    }

    func replaceAll(_ checkIns: [CheckIn]) async throws {
        var profile = profileService.profile
        profile.checkIns = checkIns
        profileService.updateProfile(profile)
    }

    func mergeWidgetCheckIn() {
        guard let raw = userDefaultsService.getLocalData(.pendingWidgetCheckIn) else { return }
        guard let pending = try? JSONDecoder().decode(PendingWidgetCheckIn.self, from: raw) else {
            userDefaultsService.clearLocalData(.pendingWidgetCheckIn)
            return
        }
        let existing = profileService.profile.checkIns.first { $0.dateString == pending.dateString }
        let shouldApply = existing == nil || pending.timestamp > existing!.date
        if shouldApply, let mood = Mood(rawValue: pending.moodRawValue) {
            let checkIn = CheckIn(dateString: pending.dateString, mood: mood, feelingsDescription: nil, factors: nil)
            Task { try? await self.save(checkIn) }
        }
        userDefaultsService.clearLocalData(.pendingWidgetCheckIn)
    }

    func reset() {
        var profile = profileService.profile
        profile.checkIns = []
        profileService.updateProfile(profile)
    }

    var hasCheckedInToday: Bool {
        profileService.profile.checkIns.contains { $0.dateString == CheckIn.dateString(for: .now) }
    }

    var todaysMood: Mood? {
        profileService.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.mood
    }

    var todaysFeelingsDescription: String? {
        profileService.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.feelingsDescription
    }

    var todaysFactors: CheckInFactors? {
        profileService.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.factors
    }

    var earliestCheckInDate: Date? {
        profileService.profile.checkIns.map { $0.date }.min()
    }

    func streakStats() -> (current: Int, longest: Int) {
        streakCalculator.compute(checkIns: profileService.profile.checkIns)
    }

    func streakStartDate() -> Date? {
        streakCalculator.startDate(checkIns: profileService.profile.checkIns)
    }

    var allCheckIns: [CheckIn] { profileService.profile.checkIns }

    func checkIn(for dateString: String) -> CheckIn? {
        profileService.profile.checkIns.first { $0.dateString == dateString }
    }

    // MARK: - Private

    private func save(_ checkIn: CheckIn) async throws {
        var profile = profileService.profile
        let dateString = checkIn.dateString
        if let idx = profile.checkIns.firstIndex(where: { $0.dateString == dateString }) {
            profile.checkIns[idx] = checkIn
        } else {
            profile.checkIns.append(checkIn)
        }
        profileService.updateProfile(profile)
        // Local state is already persisted above — network sync is advisory only
        Task { try? await checkinsService.post(checkIn) }
    }
}
