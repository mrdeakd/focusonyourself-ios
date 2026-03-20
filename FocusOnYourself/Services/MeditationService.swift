import Foundation

final class MeditationService: MeditationServiceProtocol {
    private var loaded: [MeditationSession]?

    private var isHungarian: Bool {
        Locale.current.language.languageCode?.identifier == "hu"
    }

    private func load() -> [MeditationSession] {
        if let cached = loaded { return cached }
        let result = Bundle.main.decodeJSON([MeditationSession].self, from: "meditations") ?? []
        loaded = result
        return result
    }

    func allSessions() -> [MeditationSession] {
        load()
    }

    func sessions(for category: MeditationCategory?) -> [MeditationSession] {
        guard let category else { return load() }
        return load().filter { $0.category == category }
    }

    func localizedTitle(for session: MeditationSession) -> String {
        (isHungarian ? session.titleHu : nil) ?? session.title
    }

    func localizedInstruction(for step: MeditationStep) -> String? {
        (isHungarian ? step.instructionHu : nil) ?? step.instruction
    }
}
