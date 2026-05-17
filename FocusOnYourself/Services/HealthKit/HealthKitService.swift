import Foundation
import HealthKit

final class HealthKitService: HealthKitServiceProtocol {
    private let store = HKHealthStore()

    func save(mood: Mood, factors: CheckInFactors?) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.stateOfMindType()], read: [])
        } catch {
            return
        }
        let valence = (Double(mood.numericValue) - 3.0) / 2.0
        let sample = HKStateOfMind(
            date: Date.now,
            kind: .dailyMood,
            valence: valence,
            labels: Self.labels(for: mood, factors: factors),
            associations: Self.associations(for: factors)
        )
        try? await store.save(sample)
    }

    private static func labels(for mood: Mood, factors: CheckInFactors?) -> [HKStateOfMind.Label] {
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

    private static func associations(for factors: CheckInFactors?) -> [HKStateOfMind.Association] {
        guard let factors else { return [] }
        var result: [HKStateOfMind.Association] = []
        if factors.exercised { result.append(.fitness) }
        result.append(.health)
        result.append(.community)
        return result
    }
}
