import Foundation

enum Mood: String, CaseIterable, Codable, Identifiable {
    case rough, low, okay, good, great
    var id: String { rawValue }
    var imageName: String {
        "mood-\(rawValue)"
    }
    var displayName: String {
        switch self {
        case .rough: return String(localized: "mood.rough")
        case .low:   return String(localized: "mood.low")
        case .okay:  return String(localized: "mood.okay")
        case .good:  return String(localized: "mood.good")
        case .great: return String(localized: "mood.great")
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
