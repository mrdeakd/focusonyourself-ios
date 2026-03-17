import SwiftUI

enum ArticleTopic: String, CaseIterable, Codable {
    case sleep
    case mentalHealth
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

    var color: Color {
        switch self {
        case .sleep:        return .foyNavy
        case .mentalHealth: return .foyOrange
        case .nutrition:    return .foyGreen
        case .movement:     return .foyOrangeAccent
        }
    }

    var tintColor: Color {
        switch self {
        case .sleep:        return .foyNavyTint
        case .mentalHealth: return .foyOrangeTint
        case .nutrition:    return .foyGreenTint
        case .movement:     return .foyOrangeTint
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

struct Article: Codable, Identifiable {
    let id: String
    let title: String
    let topic: ArticleTopic
    let readTimeMinutes: Int
    let body: String
}
