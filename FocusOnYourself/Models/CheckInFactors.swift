import Foundation

// IMPORTANT: All fields must remain optional or have defaults.
// Non-optional fields will cause JSONDecoder to throw on legacy CheckIn records,
// triggering ProfileService's fallback to UserProfile() and silently wiping all user history.
struct CheckInFactors: Codable, Equatable {
    var sleepQuality: Int
    var stressLevel: Int
    var exercised: Bool
    var socialQuality: Int
}
