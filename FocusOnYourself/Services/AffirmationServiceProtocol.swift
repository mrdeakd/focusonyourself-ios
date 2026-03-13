import Foundation

protocol AffirmationServiceProtocol {
    func generate(for categories: [AffirmationCategory]) async throws -> String
}
