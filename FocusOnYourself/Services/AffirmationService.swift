import Factory
import Foundation
import FoundationModels
import Observation

@Observable @MainActor final class AffirmationService: AffirmationServiceProtocol {
    private let networkClient: NetworkClientProtocol
    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaultsService

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func cachedBatch() -> [(quote: String, category: AffirmationCategory)]? {
        let today = CheckIn.dateString(for: Date.now)
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
        userDefaultsService.setString(.affirmationCacheDate, value: CheckIn.dateString(for: Date.now))
    }

    func generateBatch(
        count: Int,
        for categories: [AffirmationCategory],
        useAppleIntelligence: Bool
    ) async throws -> [(quote: String, category: AffirmationCategory)] {
        guard !categories.isEmpty else { return [] }

        if useAppleIntelligence {
            return try await generateWithAppleIntelligence(count: count, categories: categories)
        } else {
            let categoryParams = categories.map(\.rawValue).joined(separator: ",")
            let path = "/api/affirmations/batch?categories=\(categoryParams)&count=\(count)"
            let items: [CachedAffirmation] = try await networkClient.get(path)
            return items.map { (quote: $0.quote, category: $0.category) }
        }
    }

    // MARK: - Apple Intelligence path

    private func generateWithAppleIntelligence(
        count: Int,
        categories: [AffirmationCategory]
    ) async throws -> [(quote: String, category: AffirmationCategory)] {
        let counts = distribute(total: count, across: categories.count)
        var results: [(quote: String, category: AffirmationCategory)] = []

        for (category, affirmationCount) in zip(categories, counts) {
            let prompt = """
                Write \(affirmationCount) short, powerful daily affirmations in the theme of: \(category.displayName). \
                Use first person ("I am", "I have", or "I choose"). \
                Format as a numbered list (1. ... 2. ... etc.), one affirmation per line. \
                Return only the affirmation texts, no explanations.
                """
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            let quotes = parseNumberedList(response.content, expected: affirmationCount)
            results += quotes.map { (quote: $0, category: category) }
        }

        return results
    }

    // MARK: - Helpers

    private func distribute(total: Int, across count: Int) -> [Int] {
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

    private func parseNumberedList(_ text: String, expected: Int) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var results: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let stripped = trimmed.replacing(#/^\d+\.\s*/#, with: "")
            if !stripped.isEmpty {
                results.append(stripped)
            }
        }
        return Array(results.prefix(expected))
    }
}
