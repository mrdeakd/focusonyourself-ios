protocol MeditationServiceProtocol {
    func allSessions() async throws -> [MeditationSession]
    func sessions(in category: MeditationCategory) async throws -> [MeditationSession]
    func narrationMap() async throws -> [String: String]
}
