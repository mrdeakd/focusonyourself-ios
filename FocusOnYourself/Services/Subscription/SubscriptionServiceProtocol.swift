protocol SubscriptionServiceProtocol {
    func verify(signedTransaction: String) async throws -> SubscriptionVerifyResponse
}
