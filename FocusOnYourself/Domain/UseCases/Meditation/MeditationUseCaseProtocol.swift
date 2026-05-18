import Foundation

protocol MeditationUseCaseProtocol: AnyObject {
    func sessions(for category: MeditationCategory?) async throws -> [MeditationSession]
}
