import Foundation

final class MeditationService: MeditationServiceProtocol {
    private var loaded: [MeditationSession]?

    private func load() -> [MeditationSession] {
        if let cached = loaded { return cached }
        guard let url = Bundle.main.url(forResource: "meditations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([MeditationSession].self, from: data)
        else { return [] }
        loaded = decoded
        return decoded
    }

    func allSessions() -> [MeditationSession] {
        load()
    }

    func sessions(for category: MeditationCategory?) -> [MeditationSession] {
        guard let category else { return load() }
        return load().filter { $0.category == category }
    }
}
