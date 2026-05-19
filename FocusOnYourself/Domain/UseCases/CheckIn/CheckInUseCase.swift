import Factory
import Foundation

final class CheckInUseCase: CheckInUseCaseProtocol {
    @Injected(\.profileUseCase) private var profileUseCase
    @Injected(\.checkinsService) private var checkinsService
    private let streakCalculator = StreakCalculator()
    private let defaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard

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
        var profile = profileUseCase.profile
        profile.checkIns = checkIns
        profileUseCase.updateProfile(profile)
    }

    func mergeWidgetCheckIn() {
        guard let raw = defaults.data(forKey: UserDefaultsKey.pendingWidgetCheckIn.rawValue) else { return }
        guard let pending = try? JSONDecoder().decode(PendingWidgetCheckIn.self, from: raw) else {
            defaults.removeObject(forKey: UserDefaultsKey.pendingWidgetCheckIn.rawValue)
            return
        }
        let existing = profileUseCase.profile.checkIns.first { $0.dateString == pending.dateString }
        let shouldApply = existing == nil || pending.timestamp > existing!.date
        if shouldApply, let mood = Mood(rawValue: pending.moodRawValue) {
            let checkIn = CheckIn(dateString: pending.dateString, mood: mood, feelingsDescription: nil, factors: nil)
            Task { try? await self.save(checkIn) }
        }
        defaults.removeObject(forKey: UserDefaultsKey.pendingWidgetCheckIn.rawValue)
    }

    func reset() {
        var profile = profileUseCase.profile
        profile.checkIns = []
        profileUseCase.updateProfile(profile)
    }

    var hasCheckedInToday: Bool {
        profileUseCase.profile.checkIns.contains { $0.dateString == CheckIn.dateString(for: .now) }
    }

    var todaysMood: Mood? {
        profileUseCase.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.mood
    }

    var todaysFeelingsDescription: String? {
        profileUseCase.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.feelingsDescription
    }

    var todaysFactors: CheckInFactors? {
        profileUseCase.profile.checkIns.first { $0.dateString == CheckIn.dateString(for: .now) }?.factors
    }

    var earliestCheckInDate: Date? {
        profileUseCase.profile.checkIns.map { $0.date }.min()
    }

    func streakStats() -> (current: Int, longest: Int) {
        streakCalculator.compute(checkIns: profileUseCase.profile.checkIns)
    }

    func streakStartDate() -> Date? {
        streakCalculator.startDate(checkIns: profileUseCase.profile.checkIns)
    }

    var allCheckIns: [CheckIn] { profileUseCase.profile.checkIns }

    func checkIn(for dateString: String) -> CheckIn? {
        profileUseCase.profile.checkIns.first { $0.dateString == dateString }
    }

    // MARK: - Private

    private func save(_ checkIn: CheckIn) async throws {
        var profile = profileUseCase.profile
        let dateString = checkIn.dateString
        if let idx = profile.checkIns.firstIndex(where: { $0.dateString == dateString }) {
            profile.checkIns[idx] = checkIn
        } else {
            profile.checkIns.append(checkIn)
        }
        profileUseCase.updateProfile(profile)
        // Local state is already persisted above — network sync is advisory only
        Task { try? await checkinsService.post(checkIn) }
    }
}
