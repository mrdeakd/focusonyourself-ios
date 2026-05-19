import Foundation

enum ArticleTopic: String, CaseIterable, Codable {
    case sleep
    // swiftlint:disable:next redundant_string_enum_value
    case mentalHealth = "mentalHealth"
    case nutrition
    case movement

    var displayName: String {
        switch self {
        case .sleep:        return "Sleep & Recovery"
        case .mentalHealth: return "Mental Health"
        case .nutrition:    return "Nutrition & Gut Health"
        case .movement:     return "Movement & Exercise"
        }
    }

    var icon: String {
        switch self {
        case .sleep:        return "moon.fill"
        case .mentalHealth: return "brain.head.profile"
        case .nutrition:    return "leaf.fill"
        case .movement:     return "figure.run"
        }
    }
}
