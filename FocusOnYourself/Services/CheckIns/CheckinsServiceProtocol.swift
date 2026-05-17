import Foundation

protocol CheckinsServiceProtocol: AnyObject {
    func post(_ checkIn: CheckIn) async throws
    func importAll(_ checkIns: [CheckIn]) async throws
    func fetch() async throws -> [CheckIn]
}
