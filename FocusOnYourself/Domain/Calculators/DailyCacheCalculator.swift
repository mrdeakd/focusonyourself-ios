import Foundation

struct DailyCacheCalculator {
    func isFreshForToday(cachedDateString: String?) -> Bool {
        cachedDateString == CheckIn.dateString(for: Date.now)
    }

    func todayString() -> String {
        CheckIn.dateString(for: Date.now)
    }
}
