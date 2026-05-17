import Factory
import Foundation

final class CheckinsService: CheckinsServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func post(_ checkIn: CheckIn) async throws {
        _ = try await networkClient.post("/api/checkins", body: checkIn.toBackendModel()) as EmptyResponse
    }

    func importAll(_ checkIns: [CheckIn]) async throws {
        let body = ImportCheckInsBody(checkIns: checkIns.map { $0.toBackendModel() })
        _ = try await networkClient.post("/api/checkins/import", body: body) as EmptyResponse
    }

    func fetch() async throws -> [CheckIn] {
        let backends: [BackendCheckIn] = try await networkClient.get("/api/checkins")
        return backends.compactMap { $0.toDomainModel() }
    }
}
