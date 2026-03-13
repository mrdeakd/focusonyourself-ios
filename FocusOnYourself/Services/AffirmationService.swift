import Foundation
import FoundationModels

final class AffirmationService: AffirmationServiceProtocol {
    func generate(for categories: [AffirmationCategory]) async throws -> String {
        let categoryNames = categories.map(\.displayName).joined(separator: ", ")
        let prompt = """
            Write a single short, powerful daily affirmation (1–2 sentences) \
            in the theme of: \(categoryNames). \
            Use first person ("I am", "I have", or "I choose"). \
            Return only the affirmation text, no quotes, no explanation.
            """

        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
