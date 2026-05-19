import Foundation

struct AffirmationCalculator {
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

    func parseNumberedList(_ text: String, expected: Int) -> [String] {
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

    func promptFor(category: AffirmationCategory, count: Int) -> String {
        """
        Write \(count) short, powerful daily affirmations in the theme of: \(category.displayName). \
        Use first person ("I am", "I have", or "I choose"). \
        Format as a numbered list (1. ... 2. ... etc.), one affirmation per line. \
        Return only the affirmation texts, no explanations.
        """
    }
}
