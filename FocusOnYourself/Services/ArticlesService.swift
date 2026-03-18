import Foundation

final class ArticlesService: ArticlesServiceProtocol {
    private var loaded: [Article]?

    // MARK: - Internal raw model (includes bilingual fields)
    private struct RawArticle: Decodable {
        let id: String
        let title: String
        let titleHu: String?
        let topic: ArticleTopic
        let readTimeMinutes: Int
        let body: String
        let bodyHu: String?
    }

    private func load() -> [Article] {
        if let cached = loaded { return cached }
        let langCode = Locale.current.language.languageCode?.identifier
        let raw = Bundle.main.decodeJSON([RawArticle].self, from: "articles") ?? []
        let result = raw.map { raw in
            let title = (langCode == "hu" ? raw.titleHu : nil) ?? raw.title
            let body  = (langCode == "hu" ? raw.bodyHu : nil) ?? raw.body
            return Article(id: raw.id, title: title, topic: raw.topic,
                           readTimeMinutes: raw.readTimeMinutes, body: body)
        }
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
        let dateString = formatter.string(from: date)
        return dateString.unicodeScalars.reduce(UInt64(5381)) { ($0 &* 31) &+ UInt64($1.value) }
    }
}
