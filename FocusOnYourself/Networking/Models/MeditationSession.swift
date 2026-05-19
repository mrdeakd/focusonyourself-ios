import Foundation

struct MeditationSession: Codable, Identifiable {
    let id: String
    let title: String
    let category: MeditationCategory
    let durationMinutes: Int
    let isPro: Bool
    let steps: [MeditationStep]

    static let placeholder = MeditationSession(
        id: "placeholder",
        title: "Loading session title",
        category: .morning,
        durationMinutes: 10,
        isPro: false,
        steps: []
    )
}
