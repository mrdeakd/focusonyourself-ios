import Foundation

enum Mood: String, CaseIterable, Codable, Identifiable {
    case rough, low, okay, good, great
    var id: String { rawValue }
    var imageName: String {
        "mood-\(rawValue)"
    }
    var displayName: String {
        switch self {
        case .rough: return "Rough"
        case .low:   return "Low"
        case .okay:  return "Okay"
        case .good:  return "Good"
        case .great: return "Great"
        }
    }

    var numericValue: Int {
        switch self {
        case .rough: return 1
        case .low:   return 2
        case .okay:  return 3
        case .good:  return 4
        case .great: return 5
        }
    }
}
