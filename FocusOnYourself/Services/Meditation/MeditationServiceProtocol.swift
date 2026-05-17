protocol MeditationServiceProtocol {
    func sessions(for category: MeditationCategory?) async throws -> [MeditationSession]
}
