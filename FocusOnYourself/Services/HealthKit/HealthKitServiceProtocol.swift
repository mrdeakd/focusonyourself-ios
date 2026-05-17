protocol HealthKitServiceProtocol {
    func save(mood: Mood, factors: CheckInFactors?) async
}
