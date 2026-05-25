import Factory
import Foundation

final class CheckinsService: CheckinsServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func post(_ checkIn: CheckIn) async throws {
        let path = "/api/checkins"
        let body = checkIn.toBackendModel()
        do {
            let _: EmptyResponse = try await networkClient.post(path, body: body)
        } catch {
            throw Self.mapPostError(error)
        }
    }

    func importAll(_ checkIns: [CheckIn]) async throws {
        let path = "/api/checkins/import"
        let body = ImportCheckInsBody(checkIns: checkIns.map { $0.toBackendModel() })
        do {
            let _: EmptyResponse = try await networkClient.post(path, body: body)
        } catch {
            throw Self.mapImportError(error)
        }
    }

    func fetch() async throws -> [CheckIn] {
        let path = "/api/checkins"
        do {
            let response: [BackendCheckIn] = try await networkClient.get(path)
            return response.compactMap { $0.toDomainModel() }
        } catch {
            throw Self.mapFetchError(error)
        }
    }

    private static func mapPostError(_ error: Error) -> CheckInError { .postFailed }
    private static func mapImportError(_ error: Error) -> CheckInError { .importFailed }
    private static func mapFetchError(_ error: Error) -> CheckInError { .fetchFailed }
}
