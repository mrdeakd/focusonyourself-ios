import SwiftUI

enum MeditationCategory: String, CaseIterable, Codable {
    case morning
    case focus
    case anxiety
    case sleep

    var displayName: String {
        switch self {
        case .morning: return String(localized: "meditation.morning")
        case .focus:   return String(localized: "meditation.focus")
        case .anxiety: return String(localized: "meditation.anxiety")
        case .sleep:   return String(localized: "meditation.sleep")
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
    let instructionHu: String?
    let silenceDurationSeconds: Int?
}

struct MeditationSession: Codable, Identifiable {
    let id: String
    let title: String
    let titleHu: String?
    let category: MeditationCategory
    let durationMinutes: Int
    let isPro: Bool
    let steps: [MeditationStep]
}
