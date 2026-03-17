import Foundation

final class ArticlesService: ArticlesServiceProtocol {
    private var loaded: [Article]?

    private func load() -> [Article] {
        if let cached = loaded { return cached }
        guard let url = Bundle.main.url(forResource: "articles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Article].self, from: data)
        else { return [] }
        loaded = decoded
        return decoded
    }

    func allArticles() -> [Article] {
        load()
    }

    func articles(for topic: ArticleTopic?) -> [Article] {
        guard let topic else { return load() }
        return load().filter { $0.topic == topic }
    }
}
