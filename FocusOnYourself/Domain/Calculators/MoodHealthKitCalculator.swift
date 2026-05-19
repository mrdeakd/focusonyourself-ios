import Foundation
import HealthKit

struct MoodHealthKitCalculator {
    func valence(for mood: Mood) -> Double {
        (Double(mood.numericValue) - 3.0) / 2.0
    }

    // swiftlint:disable:next cyclomatic_complexity
    func labels(for mood: Mood, factors: CheckInFactors?) -> [HKStateOfMind.Label] {
        var result: [HKStateOfMind.Label] = []
        switch mood {
        case .great: result.append(.joyful)
        case .good:  result.append(.content)
        case .rough: result.append(.sad)
        case .low, .okay: break
        }
        guard let factors else { return result }
        switch factors.stressLevel {
        case 5: result.append(.overwhelmed)
        case 4: result.append(.stressed)
        case 2: result.append(.calm)
        case 1: result.append(.peaceful)
        default: break
        }
        if factors.sleepQuality <= 2 { result.append(.drained) }
        if factors.socialQuality <= 2 { result.append(.lonely) }
        return result
    }

    func associations(for factors: CheckInFactors?) -> [HKStateOfMind.Association] {
        guard let factors else { return [.health, .community] }
        var result: [HKStateOfMind.Association] = []
        if factors.exercised { result.append(.fitness) }
        result.append(.health)
        result.append(.community)
        return result
    }
}
