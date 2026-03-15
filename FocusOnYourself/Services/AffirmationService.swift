import Foundation
import FoundationModels

final class AffirmationService: AffirmationServiceProtocol {
    private var staticAffirmations: [(quote: String, category: AffirmationCategory)]?
    private let userDefaultsService: UserDefaultsServiceProtocol

    init(userDefaultsService: UserDefaultsServiceProtocol = ServiceContainer.shared.userDefaultsService) {
        self.userDefaultsService = userDefaultsService
    }

    func cachedBatch() -> [(quote: String, category: AffirmationCategory)]? {
        let today = CheckIn.dateString(for: Date())
        guard userDefaultsService.getString(.affirmationCacheDate) == today,
              let data = userDefaultsService.getData(.affirmationCache),
              let cached = try? JSONDecoder().decode([CachedAffirmation].self, from: data)
        else { return nil }
        return cached.map { (quote: $0.quote, category: $0.category) }
    }

    func cacheBatch(_ pairs: [(quote: String, category: AffirmationCategory)]) {
        let cached = pairs.map { CachedAffirmation(quote: $0.quote, category: $0.category) }
        if let data = try? JSONEncoder().encode(cached) {
            userDefaultsService.setData(.affirmationCache, value: data)
        }
        userDefaultsService.setString(.affirmationCacheDate, value: CheckIn.dateString(for: Date()))
    }

    func generateBatch(count: Int, for categories: [AffirmationCategory], useAppleIntelligence: Bool) async throws -> [(quote: String, category: AffirmationCategory)] {
        guard !categories.isEmpty else { return [] }

        if useAppleIntelligence {
            return try await generateWithAppleIntelligence(count: count, categories: categories)
        } else {
            return try loadStaticBatch(count: count, categories: categories)
        }
    }

    // MARK: - Apple Intelligence path

    private func generateWithAppleIntelligence(count: Int, categories: [AffirmationCategory]) async throws -> [(quote: String, category: AffirmationCategory)] {
        let counts = distribute(total: count, across: categories.count)
        var results: [(quote: String, category: AffirmationCategory)] = []

        for (category, n) in zip(categories, counts) {
            let prompt = """
                Write \(n) short, powerful daily affirmations in the theme of: \(category.displayName). \
                Use first person ("I am", "I have", or "I choose"). \
                Format as a numbered list (1. ... 2. ... etc.), one affirmation per line. \
                Return only the affirmation texts, no explanations.
                """
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            let quotes = parseNumberedList(response.content, expected: n)
            results += quotes.map { (quote: $0, category: category) }
        }

        return results
    }

    // MARK: - Static dataset path

    private func loadStaticAffirmations() throws -> [(quote: String, category: AffirmationCategory)] {
        if let cached = staticAffirmations { return cached }

        guard let url = Bundle.main.url(forResource: "affirmations", withExtension: "json") else {
            throw AffirmationServiceError.datasetNotFound
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([StaticAffirmation].self, from: data)
        let result = decoded.compactMap { entry -> (quote: String, category: AffirmationCategory)? in
            guard let category = AffirmationCategory(rawValue: entry.category) else { return nil }
            return (quote: entry.quote, category: category)
        }
        staticAffirmations = result
        return result
    }

    private func loadStaticBatch(
        count: Int, categories: [AffirmationCategory]
    ) throws -> [(quote: String, category: AffirmationCategory)] {
        let all = try loadStaticAffirmations()
        let categorySet = Set(categories)
        let filtered = all.filter { categorySet.contains($0.category) }
        guard !filtered.isEmpty else { return [] }
        let shuffled = filtered.shuffled()
        return Array(shuffled.prefix(count))
    }

    // MARK: - Helpers

    private func distribute(total: Int, across count: Int) -> [Int] {
        guard count > 0 else { return [] }
        var counts = [Int](repeating: 1, count: count)
        var remaining = total - count
        while remaining > 0 {
            counts[Int.random(in: 0..<count)] += 1
            remaining -= 1
        }
        return counts
    }

    private func parseNumberedList(_ text: String, expected: Int) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var results: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let stripped = trimmed.replacingOccurrences(
                of: #"^\d+\.\s*"#,
                with: "",
                options: .regularExpression
            )
            if !stripped.isEmpty {
                results.append(stripped)
            }
        }
        return Array(results.prefix(expected))
    }
}

enum AffirmationServiceError: Error {
    case datasetNotFound
}
