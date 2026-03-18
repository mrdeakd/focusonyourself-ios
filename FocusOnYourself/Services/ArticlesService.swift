import Foundation

final class ArticlesService: ArticlesServiceProtocol {
    private var loaded: [Article]?

    private func load() -> [Article] {
        if let cached = loaded { return cached }
        let result = Bundle.main.decodeJSON([Article].self, from: "articles") ?? []
        loaded = result
        return result
    }

    func allArticles() -> [Article] {
        load()
    }

    func dailyArticles() -> [Article] {
        var rng = SeededRNG(seed: dateHash(Date()))
        return Array(load().shuffled(using: &rng).prefix(4))
    }

    func articles(for topic: ArticleTopic?) -> [Article] {
        guard let topic else { return load() }
        return load().filter { $0.topic == topic }
    }

    // MARK: - Private helpers

    private struct SeededRNG: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { state = seed == 0 ? 1 : seed }
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    private func dateHash(_ date: Date) -> UInt64 {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let s = formatter.string(from: date)
        return s.unicodeScalars.reduce(UInt64(5381)) { ($0 &* 31) &+ UInt64($1.value) }
    }
}
