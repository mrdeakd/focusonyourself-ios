import Factory
import Foundation

final class CheckinsService: CheckinsServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func post(_ checkIn: CheckIn) async throws {
        let path = "/api/checkins"
        let body = checkIn.toBackendModel()
        let _: EmptyResponse = try await networkClient.post(path, body: body)
    }

    func importAll(_ checkIns: [CheckIn]) async throws {
        let path = "/api/checkins/import"
        let body = ImportCheckInsBody(checkIns: checkIns.map { $0.toBackendModel() })
        let _: EmptyResponse = try await networkClient.post(path, body: body)
    }

    func fetch() async throws -> [CheckIn] {
        let path = "/api/checkins"
        let response: [BackendCheckIn] = try await networkClient.get(path)
        return response.compactMap { $0.toDomainModel() }
    }
}
