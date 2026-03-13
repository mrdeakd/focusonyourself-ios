import Foundation
import FoundationModels

final class AffirmationService: AffirmationServiceProtocol {
    func generateBatch(count: Int, for categories: [AffirmationCategory]) async throws -> [(quote: String, category: AffirmationCategory)] {
        guard !categories.isEmpty else { return [] }

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
