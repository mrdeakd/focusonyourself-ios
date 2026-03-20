protocol MeditationServiceProtocol {
    func allSessions() -> [MeditationSession]
    func sessions(for category: MeditationCategory?) -> [MeditationSession]
    func localizedTitle(for session: MeditationSession) -> String
    func localizedInstruction(for step: MeditationStep) -> String?
}
