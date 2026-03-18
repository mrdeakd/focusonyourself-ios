import Foundation

enum AffirmationCategory: String, CaseIterable, Codable, Identifiable {
    case confidence, health, relationships, mindfulness, career, resilience
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .confidence:    return String(localized: "category.confidence")
        case .health:        return String(localized: "category.health")
        case .relationships: return String(localized: "category.relationships")
        case .mindfulness:   return String(localized: "category.mindfulness")
        case .career:        return String(localized: "category.career")
        case .resilience:    return String(localized: "category.resilience")
        }
    }
    var isFree: Bool {
        self == .confidence || self == .mindfulness
    }
}
