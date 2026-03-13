import Foundation

enum Mood: String, CaseIterable, Codable, Identifiable {
    case rough, low, okay, good, great
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .rough: return "😞"
        case .low:   return "😕"
        case .okay:  return "😐"
        case .good:  return "🙂"
        case .great: return "😄"
        }
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
}
