import Foundation

struct DistributionCalculator {
    /// Distributes `total` items as fairly as possible into `count` buckets.
    /// Each bucket gets at least 1; the remainder is sprinkled randomly.
    func distribute(total: Int, across count: Int) -> [Int] {
        // swiftlint:disable:next empty_count
        guard count > 0 else { return [] }
        var counts = [Int](repeating: 1, count: count)
        var remaining = total - count
        while remaining > 0 {
            counts[Int.random(in: 0..<count)] += 1
            remaining -= 1
        }
        return counts
    }
}
