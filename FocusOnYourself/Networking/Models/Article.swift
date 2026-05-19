import Foundation

struct Article: Codable, Identifiable {
    let id: String
    let title: String
    let topic: ArticleTopic
    let readTimeMinutes: Int
    let body: String

    static let placeholder = Article(
        id: "placeholder",
        title: "Loading article title here",
        topic: .sleep,
        readTimeMinutes: 3,
        body: ""
    )
}
