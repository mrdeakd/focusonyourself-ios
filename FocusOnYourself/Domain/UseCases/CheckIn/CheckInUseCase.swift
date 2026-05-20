import Factory
import Foundation

final class CheckInUseCase: CheckInUseCaseProtocol {
    @Injected(\.profileUseCase) private var profileUseCase
    @Injected(\.checkinsService) private var checkinsService
    @Injected(\.userDefaultsStore) private var userDefaultsStore
    private let streakCalculator = StreakCalculator()

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

    var allCheckIns: [CheckIn] { profileUseCase.profile.checkIns }

    // MARK: - Public methods

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
        profileUseCase.updateCheckIns(checkIns)
    }

    func mergeWidgetCheckIn() {
        guard let raw = userDefaultsStore.data(for: .pendingWidgetCheckIn) else { return }
        guard let pending = try? JSONDecoder().decode(PendingWidgetCheckIn.self, from: raw) else {
            userDefaultsStore.remove(.pendingWidgetCheckIn)
            return
        }
        let existing = profileUseCase.profile.checkIns.first { $0.dateString == pending.dateString }
        let shouldApply = existing == nil || pending.timestamp > existing!.date
        if shouldApply, let mood = Mood(rawValue: pending.moodRawValue) {
            let checkIn = CheckIn(dateString: pending.dateString, mood: mood, feelingsDescription: nil, factors: nil)
            Task { try? await self.save(checkIn) }
        }
        userDefaultsStore.remove(.pendingWidgetCheckIn)
    }

    func reset() {
        profileUseCase.updateCheckIns([])
    }

    func uploadAllToServer() async throws {
        let checkIns = profileUseCase.profile.checkIns
        guard !checkIns.isEmpty else { return }
        try await checkinsService.importAll(checkIns)
    }

    func downloadAndReplaceFromServer() async throws {
        let checkIns = try await checkinsService.fetch()
        try await replaceAll(checkIns)
    }

    func streakStats() -> (current: Int, longest: Int) {
        streakCalculator.compute(checkIns: profileUseCase.profile.checkIns)
    }

    func streakStartDate() -> Date? {
        streakCalculator.startDate(checkIns: profileUseCase.profile.checkIns)
    }

    func checkIn(for dateString: String) -> CheckIn? {
        profileUseCase.profile.checkIns.first { $0.dateString == dateString }
    }

    // MARK: - Private

    private func save(_ checkIn: CheckIn) async throws {
        var checkIns = profileUseCase.profile.checkIns
        if let idx = checkIns.firstIndex(where: { $0.dateString == checkIn.dateString }) {
            checkIns[idx] = checkIn
        } else {
            checkIns.append(checkIn)
        }
        profileUseCase.updateCheckIns(checkIns)
        // Local state is already persisted above — network sync is advisory only
        Task { try? await checkinsService.post(checkIn) }
    }
}
