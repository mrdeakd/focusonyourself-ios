import Factory
import Foundation

final class CheckInRepositoryImpl: CheckInRepositoryProtocol {
    @Injected(\.profileService) private var profileService
    @Injected(\.checkinsService) private var checkinsService
    @Injected(\.userDefaultsService) private var userDefaultsService

    func save(_ checkIn: CheckIn) async throws {
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

    func replaceAll(_ checkIns: [CheckIn]) async throws {
        var profile = profileService.profile
        profile.checkIns = checkIns
        profileService.updateProfile(profile)
    }

    func fetchFromServer() async throws -> [CheckIn] {
        try await checkinsService.fetch()
    }

    func uploadAll(_ checkIns: [CheckIn]) async throws {
        guard !checkIns.isEmpty else { return }
        try await checkinsService.importAll(checkIns)
    }

    func reset() {
        var profile = profileService.profile
        profile.checkIns = []
        profileService.updateProfile(profile)
    }

    func mergePendingWidgetCheckIn() {
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
}
