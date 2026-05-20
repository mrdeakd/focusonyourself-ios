import Foundation

struct JWTExpiryCalculator {
    private static let nearExpirySeconds: TimeInterval = 60

    func isNearExpiry(_ token: String) -> Bool {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count == 3 else { return true }
        let payload = paddedBase64(parts[1])
        guard let data = Data(base64Encoded: payload) else { return true }
        guard let jwt = try? JSONDecoder().decode(JWTPayload.self, from: data) else { return true }
        return jwt.exp - Date().timeIntervalSince1970 < Self.nearExpirySeconds
    }

    private func paddedBase64(_ string: String) -> String {
        let remainder = string.count % 4
        guard remainder != 0 else { return string }
        return string + String(repeating: "=", count: 4 - remainder)
    }

    private struct JWTPayload: Decodable {
        let exp: Double
    }
}
