import Foundation

struct ErrorInfo {
    let title: String
    let description: String?

    init(title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }

    init(_ error: UserFacingError) {
        self.init(title: error.errorTitle, description: error.errorDescription)
    }
}
