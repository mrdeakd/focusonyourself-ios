import Factory
import Foundation

final class SubscriptionService: SubscriptionServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func verify(signedTransaction: String) async throws -> SubscriptionVerifyResponse {
        let path = "/api/subscriptions/verify"
        let body = SubscriptionVerifyBody(signedTransaction: signedTransaction)
        do {
            let response: SubscriptionVerifyResponse = try await networkClient.post(path, body: body)
            return response
        } catch {
            throw Self.mapVerifyError(error)
        }
    }

    private static func mapVerifyError(_ error: Error) -> SubscriptionError {
        switch (error as? NetworkError)?.statusCode {
        case 401: .unauthorized
        case 400: .invalidTransaction
        default:  .verificationFailed
        }
    }
}
