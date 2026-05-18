import Foundation

struct FactorCorrelation: Identifiable {
    let id: String
    let factor: String
    let pearsonR: Double
    var directionLabel: String { pearsonR >= 0 ? "↑ mood" : "↓ mood" }
}

struct FactorRangeGroup {
    let label: String
    let average: Double?
    let count: Int
}

struct InsightsCalculator {
    private static let factorMinimum = 10

    func recentCheckIns(from checkIns: [CheckIn], days: Int) -> [CheckIn] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: Date.now)) ?? Date.now
        return checkIns.filter { $0.date >= cutoff }
    }

    func checkInCount(from checkIns: [CheckIn], days: Int) -> Int {
        recentCheckIns(from: checkIns, days: days).count
    }

    func averageMood(from checkIns: [CheckIn], days: Int) -> Mood? {
        let recent = recentCheckIns(from: checkIns, days: days)
        guard let avg = averageMoodValue(from: recent) else { return nil }
        return Mood.allCases.first { $0.numericValue == Int(avg.rounded()) }
    }

    func averageMoodText(from checkIns: [CheckIn], days: Int) -> String {
        let recent = recentCheckIns(from: checkIns, days: days)
        guard let avg = averageMoodValue(from: recent) else { return "—" }
        return Mood.allCases.first { $0.numericValue == Int(avg.rounded()) }?.displayName ?? "—"
    }

    func dailyMoodData(from checkIns: [CheckIn], days: Int) -> [(label: String, checkIn: CheckIn?)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date.now)
        return (0..<days).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let dateString = CheckIn.dateString(for: date)
            let checkIn = checkIns.first { $0.dateString == dateString }
            return (label: date.dayOfWeekAbbreviated, checkIn: checkIn)
        }
    }

    func weeklyAverages(from checkIns: [CheckIn]) -> [(week: String, avg: Double)] {
        let cal = Calendar.current
        let today = Date.now
        return (0..<4).reversed().map { weekOffset in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else {
                return (week: "W?", avg: 0)
            }
            guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: weekStart) else {
                return (week: "W?", avg: 0)
            }
            let weekly = checkIns.filter { weekInterval.contains($0.date) }
            let avg = averageMoodValue(from: weekly) ?? 0.0
            return (week: weekInterval.start.weekStart, avg: avg)
        }
    }

    func monthlyAverages(from checkIns: [CheckIn]) -> [(month: String, avg: Double)] {
        let cal = Calendar.current
        let today = Date.now
        return (0..<6).reversed().map { offset in
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: today) else {
                return (month: "?", avg: 0)
            }
            guard let monthInterval = cal.dateInterval(of: .month, for: monthDate) else {
                return (month: "?", avg: 0)
            }
            let monthly = checkIns.filter { monthInterval.contains($0.date) }
            let avg = averageMoodValue(from: monthly) ?? 0.0
            return (month: monthInterval.start.monthAbbreviated, avg: avg)
        }
    }

    func moodDistribution(from checkIns: [CheckIn], days: Int) -> [(mood: Mood, count: Int)] {
        let recent = recentCheckIns(from: checkIns, days: days)
        return Mood.allCases.reversed().map { mood in
            (mood: mood, count: recent.filter { $0.mood == mood }.count)
        }
    }

    func factorCorrelations(from checkIns: [CheckIn]) -> [FactorCorrelation] {
        let entries = checkIns.filter { $0.factors != nil }
        guard entries.count >= Self.factorMinimum else { return [] }
        let moods = entries.map { Double($0.mood.numericValue) }
        var results: [FactorCorrelation] = []
        if let corr = Self.pearsonCorrelation(entries.map { Double($0.factors!.sleepQuality) }, moods) {
            results.append(FactorCorrelation(id: "sleep", factor: "Sleep Quality", pearsonR: corr))
        }
        if let corr = Self.pearsonCorrelation(entries.map { Double($0.factors!.stressLevel) }, moods) {
            results.append(FactorCorrelation(id: "stress", factor: "Stress Level", pearsonR: corr))
        }
        if let corr = Self.pearsonCorrelation(entries.map { $0.factors!.exercised ? 1.0 : 0.0 }, moods) {
            results.append(FactorCorrelation(id: "exercise", factor: "Exercise", pearsonR: corr))
        }
        if let corr = Self.pearsonCorrelation(entries.map { Double($0.factors!.socialQuality) }, moods) {
            results.append(FactorCorrelation(id: "social", factor: "Social Quality", pearsonR: corr))
        }
        return results.sorted { abs($0.pearsonR) > abs($1.pearsonR) }
    }

    func topMoodBooster(from checkIns: [CheckIn]) -> FactorCorrelation? {
        factorCorrelations(from: checkIns).first
    }

    func averageMood(
        from checkIns: [CheckIn],
        forBinaryFactor keyPath: KeyPath<CheckInFactors, Bool>
    ) -> (with: Double?, without: Double?) {
        let entries = checkIns.filter { $0.factors != nil }.compactMap { checkIn -> (mood: Int, flag: Bool)? in
            guard let factors = checkIn.factors else { return nil }
            return (checkIn.mood.numericValue, factors[keyPath: keyPath])
        }
        let withMoods = entries.filter { $0.flag }.map { Double($0.mood) }
        let withoutMoods = entries.filter { !$0.flag }.map { Double($0.mood) }
        let avg: ([Double]) -> Double? = { arr in arr.isEmpty ? nil : arr.reduce(0, +) / Double(arr.count) }
        return (avg(withMoods), avg(withoutMoods))
    }

    // swiftlint:disable:next line_length
    func averageMoodByRange(from checkIns: [CheckIn], forFactor keyPath: KeyPath<CheckInFactors, Int>) -> (low: FactorRangeGroup, mid: FactorRangeGroup, high: FactorRangeGroup) {
        let entries = checkIns.filter { $0.factors != nil }.compactMap { checkIn -> (mood: Int, value: Int)? in
            guard let factors = checkIn.factors else { return nil }
            return (checkIn.mood.numericValue, factors[keyPath: keyPath])
        }
        func group(_ predicate: (Int) -> Bool) -> FactorRangeGroup {
            let matched = entries.filter { predicate($0.value) }
            let avg: Double? = matched.isEmpty ? nil : Double(matched.map(\.mood).reduce(0, +)) / Double(matched.count)
            return FactorRangeGroup(label: "", average: avg, count: matched.count)
        }
        return (
            low: group { $0 <= 2 },
            mid: group { $0 == 3 },
            high: group { $0 >= 4 }
        )
    }

    func bestDayOfWeek(from checkIns: [CheckIn], days: Int) -> String? {
        let recent = recentCheckIns(from: checkIns, days: days)
        guard !recent.isEmpty else { return nil }
        let cal = Calendar.current
        var byWeekday: [Int: [Int]] = [:]
        for checkIn in recent {
            let weekday = cal.component(.weekday, from: checkIn.date)
            byWeekday[weekday, default: []].append(checkIn.mood.numericValue)
        }
        guard let best = byWeekday.max(by: { dayA, dayB in
            let avgA = Double(dayA.value.reduce(0, +)) / Double(dayA.value.count)
            let avgB = Double(dayB.value.reduce(0, +)) / Double(dayB.value.count)
            return avgA < avgB
        }) else { return nil }
        let date = cal.date(bySetting: .weekday, value: best.key, of: Date.now) ?? Date.now
        return date.dayOfWeekFull
    }

    func averageMoodValue(from checkIns: [CheckIn]) -> Double? {
        guard !checkIns.isEmpty else { return nil }
        return Double(checkIns.map { $0.mood.numericValue }.reduce(0, +)) / Double(checkIns.count)
    }

    private static func pearsonCorrelation(_ xs: [Double], _ ys: [Double]) -> Double? {
        guard xs.count == ys.count, xs.count > 1 else { return nil }
        let count = Double(xs.count)
        let meanX = xs.reduce(0, +) / count
        let meanY = ys.reduce(0, +) / count
        let numerator = zip(xs, ys).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +)
        let denomX = sqrt(xs.map { pow($0 - meanX, 2) }.reduce(0, +))
        let denomY = sqrt(ys.map { pow($0 - meanY, 2) }.reduce(0, +))
        guard denomX > 0, denomY > 0 else { return nil }
        return numerator / (denomX * denomY)
    }
}
