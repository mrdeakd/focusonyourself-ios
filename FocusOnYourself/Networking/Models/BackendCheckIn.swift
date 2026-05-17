import Foundation

struct BackendCheckIn: Codable {
    let dateString: String
    let mood: String
    let feelingsDescription: String?
    let sleepQuality: Int?
    let stressLevel: Int?
    let exercised: Bool?
    let socialQuality: Int?
}

struct ImportCheckInsBody: Encodable {
    let checkIns: [BackendCheckIn]
}

extension CheckIn {
    func toBackendModel() -> BackendCheckIn {
        BackendCheckIn(
            dateString: dateString,
            mood: mood.rawValue,
            feelingsDescription: feelingsDescription,
            sleepQuality: factors?.sleepQuality,
            stressLevel: factors?.stressLevel,
            exercised: factors?.exercised,
            socialQuality: factors?.socialQuality
        )
    }
}

extension BackendCheckIn {
    func toDomainModel() -> CheckIn? {
        guard let mood = Mood(rawValue: mood) else { return nil }
        let factors: CheckInFactors? = {
            guard let sleepQuality, let stressLevel,
                let exercised, let socialQuality else { return nil }
            return CheckInFactors(
                sleepQuality: sleepQuality,
                stressLevel: stressLevel,
                exercised: exercised,
                socialQuality: socialQuality
            )
        }()
        return CheckIn(dateString: dateString, mood: mood, feelingsDescription: feelingsDescription, factors: factors)
    }
}
