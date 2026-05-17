import Foundation

enum MeditationCategory: String, CaseIterable, Codable {
    case morning
    case focus
    case anxiety
    case sleep

    var displayName: String {
        switch self {
        case .morning: return "Morning & Energy"
        case .focus:   return "Focus & Productivity"
        case .anxiety: return "Anxiety & Stress"
        case .sleep:   return "Sleep & Rest"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .focus:   return "brain.head.profile"
        case .anxiety: return "wind"
        case .sleep:   return "moon.fill"
        }
    }
}

struct MeditationStep: Codable {
    let instruction: String?
    let silenceDurationSeconds: Int?
}

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
