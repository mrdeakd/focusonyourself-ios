import Foundation

protocol CheckInRepositoryProtocol: AnyObject {
    func save(_ checkIn: CheckIn) async throws
    func replaceAll(_ checkIns: [CheckIn]) async throws
    func fetchFromServer() async throws -> [CheckIn]
    func uploadAll(_ checkIns: [CheckIn]) async throws
    func reset()
    func mergePendingWidgetCheckIn()
}
