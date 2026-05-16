import Foundation

struct ErrorInfo {
    let title: String
    let description: String?

    init(title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }
}
