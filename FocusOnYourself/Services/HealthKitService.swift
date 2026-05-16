import Foundation
import HealthKit

@available(iOS 18, *)
@Observable @MainActor
final class HealthKitService {
    private let store = HKHealthStore()
    private var isAuthorized = false

    func requestAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let stateOfMindType = HKObjectType.stateOfMindType()
        do {
            try await store.requestAuthorization(toShare: [stateOfMindType], read: [])
            isAuthorized = true
        } catch {
            // Authorization failure is non-fatal; writes fail silently
        }
    }

    func writeStateOfMind(mood: Mood, factors: CheckInFactors?) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let valence = (Double(mood.numericValue) - 3.0) / 2.0
        let labels = Self.labels(for: mood, factors: factors)
        let associations = Self.associations(for: factors)
        let sample = HKStateOfMind(
            date: Date.now,
            kind: .dailyMood,
            valence: valence,
            labels: labels,
            associations: associations
        )
        Task.detached { [store] in
            try? await store.save(sample)
        }
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

        if let stressLabel = stressLabel(for: factors.stressLevel) {
            result.append(stressLabel)
        }
        if factors.sleepQuality <= 2 { result.append(.drained) }
        if factors.socialQuality <= 2 { result.append(.lonely) }

        return result
    }

    private static func stressLabel(for level: Int) -> HKStateOfMind.Label? {
        switch level {
        case 5: return .overwhelmed
        case 4: return .stressed
        case 2: return .calm
        case 1: return .peaceful
        default: return nil
        }
    }

    private static func associations(for factors: CheckInFactors?) -> [HKStateOfMind.Association] {
        guard let factors else { return [] }
        var result: [HKStateOfMind.Association] = []
        if factors.exercised { result.append(.fitness) }
        result.append(.health)      // sleep quality was tracked
        result.append(.community)   // social quality was tracked
        return result
    }
}
