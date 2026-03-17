protocol MeditationServiceProtocol {
    func allSessions() -> [MeditationSession]
    func sessions(for category: MeditationCategory?) -> [MeditationSession]
}
