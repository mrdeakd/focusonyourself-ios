import Foundation

enum AffirmationCategory: String, CaseIterable, Codable, Identifiable {
    case confidence, health, relationships, mindfulness, career, resilience
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .confidence:    return "Confidence & Self-Worth"
        case .health:        return "Health & Body"
        case .relationships: return "Relationships & Love"
        case .mindfulness:   return "Mindfulness & Calm"
        case .career:        return "Career & Success"
        case .resilience:    return "Resilience & Strength"
        }
    }
    var isFree: Bool {
        self == .confidence || self == .mindfulness
    }
}
