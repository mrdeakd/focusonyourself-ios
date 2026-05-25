import Factory
import Foundation
import Observation
import WidgetKit

@Observable @MainActor
final class CheckInUseCase: CheckInUseCaseProtocol {
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.checkinsService) private var checkinsService
    @ObservationIgnored @Injected(\.streaksService) private var streaksService
    @ObservationIgnored @Injected(\.userDefaultsStore) private var userDefaultsStore
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    // MARK: - State

    private(set) var serverStreaks: ServerStreakStats?

    // MARK: - Computed

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

    init() {
        guard let data = _userDefaultsStore.wrappedValue.data(for: .serverStreakStats) else { return }
        serverStreaks = try? JSONDecoder().decode(ServerStreakStats.self, from: data)
    }

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
        try? await refreshStreaksFromServer()
    }

    func refreshStreaksFromServer() async throws {
        let timezone = TimeZone.current.identifier
        let response = try await streaksService.fetchMyStreaks(timezone: timezone)
        let stats = ServerStreakStats(
            currentStreak: response.currentStreak,
            longestStreak: response.longestStreak,
            streakStartDate: response.streakStartDate,
            lastCheckInDate: response.lastCheckInDate
        )
        serverStreaks = stats
        if let data = try? JSONEncoder().encode(stats) {
            userDefaultsStore.setData(data, for: .serverStreakStats)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func streakStats() -> (current: Int, longest: Int) {
        (current: serverStreaks?.currentStreak ?? 0, longest: serverStreaks?.longestStreak ?? 0)
    }

    func checkIn(for dateString: String) -> CheckIn? {
        profileUseCase.profile.checkIns.first { $0.dateString == dateString }
    }

    // MARK: - Private methods

    private func save(_ checkIn: CheckIn) async throws {
        var checkIns = profileUseCase.profile.checkIns
        if let idx = checkIns.firstIndex(where: { $0.dateString == checkIn.dateString }) {
            checkIns[idx] = checkIn
        } else {
            checkIns.append(checkIn)
        }
        profileUseCase.updateCheckIns(checkIns)
        Task { try? await checkinsService.post(checkIn) }
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in try? await self?.refreshStreaksFromServer() }
    }
}
