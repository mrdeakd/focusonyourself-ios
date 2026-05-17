import Foundation

struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
