## ADDED Requirements

### Requirement: Subscription model exists in the database
The backend SHALL define a Prisma `Subscription` model with `id`, `userId` (relation to `User`), `productId String`, `originalTransactionId String @unique`, `expiresAt DateTime`, `status String` (one of `active`, `expired`, `revoked`, `in_grace_period`), `environment String` (`Sandbox` or `Production`), `lastVerifiedAt DateTime`, `createdAt`, `updatedAt`, and an index on `userId`.

#### Scenario: Migration runs cleanly
- **WHEN** `npx prisma migrate deploy` is run against a fresh database
- **THEN** the `Subscription` table is created with the columns and unique constraint on `originalTransactionId`

### Requirement: POST /api/subscriptions/verify validates the JWS and upserts a Subscription row
The backend SHALL expose `POST /api/subscriptions/verify` behind `requireAuth`, accepting `{ signedTransaction: String }` (a JWS produced by `Transaction.jwsRepresentation` on iOS). The backend SHALL verify the JWS using Apple's `app-store-server-library`, decode the payload, validate `payload.bundleId === APPLE_BUNDLE_ID`, then upsert the `Subscription` row keyed by `originalTransactionId`. The response SHALL be `{ isPro: Bool, expiresAt: ISO8601?, productId: String? }` reflecting the user's overall Pro state, not just the row just upserted.

#### Scenario: Valid sandbox transaction is verified and stored
- **WHEN** an authenticated client POSTs a valid sandbox `signedTransaction` for the configured bundle ID
- **THEN** the response is HTTP 200 with `{ isPro: true, expiresAt: <future date>, productId: <product id> }` AND a `Subscription` row exists with that `originalTransactionId`

#### Scenario: Verify is idempotent
- **WHEN** the same `signedTransaction` is POSTed twice
- **THEN** both responses are equal AND only one `Subscription` row exists for that `originalTransactionId`

#### Scenario: Invalid JWS is rejected
- **WHEN** a client POSTs a `signedTransaction` whose signature fails verification (tampered or malformed)
- **THEN** the response is HTTP 400

#### Scenario: Bundle ID mismatch is rejected
- **WHEN** a client POSTs a valid JWS whose `bundleId` does not match `APPLE_BUNDLE_ID`
- **THEN** the response is HTTP 400

#### Scenario: Missing body is rejected
- **WHEN** a client POSTs `{}` or omits `signedTransaction`
- **THEN** the response is HTTP 400

#### Scenario: Unauthenticated request is rejected
- **WHEN** a client POSTs without a valid bearer token
- **THEN** the response is HTTP 401

### Requirement: isPro is computed from the user's subscription rows
The backend SHALL expose a helper `isUserPro(userId)` returning `true` if and only if at least one `Subscription` row for that user has `status ∈ {active, in_grace_period}` AND `expiresAt > now`. The helper SHALL be reused by `POST /api/subscriptions/verify` and any profile endpoint.

#### Scenario: Active subscription returns Pro
- **WHEN** a user has one subscription row with `status = 'active'` and `expiresAt` 30 days in the future
- **THEN** `isUserPro(userId)` returns `true`

#### Scenario: Expired subscription returns not-Pro
- **WHEN** a user has one subscription row with `status = 'expired'`
- **THEN** `isUserPro(userId)` returns `false`

#### Scenario: Revoked subscription returns not-Pro
- **WHEN** a user has one subscription row with `status = 'revoked'`
- **THEN** `isUserPro(userId)` returns `false`

#### Scenario: Grace period counts as Pro
- **WHEN** a user has one subscription row with `status = 'in_grace_period'` and `expiresAt` in the past but the grace window is still open
- **THEN** `isUserPro(userId)` returns `true`

### Requirement: Profile endpoint exposes isPro and proExpiresAt
The backend SHALL extend the existing profile endpoint (`GET /api/me` or equivalent) to include `isPro: Bool` and `proExpiresAt: ISO8601?` in its response. The values SHALL be computed via `isUserPro(userId)` and the most recent active subscription's `expiresAt`.

#### Scenario: Pro user profile
- **WHEN** an authenticated Pro user fetches their profile
- **THEN** the response includes `isPro: true` AND `proExpiresAt` is set to the active subscription's `expiresAt`

#### Scenario: Free user profile
- **WHEN** an authenticated user with no active subscription fetches their profile
- **THEN** the response includes `isPro: false` AND `proExpiresAt` is `null`

### Requirement: POST /api/subscriptions/notifications accepts App Store Server Notifications V2
The backend SHALL expose `POST /api/subscriptions/notifications` as an unauthenticated endpoint accepting `{ signedPayload: String }`. The backend SHALL verify the signed payload via Apple's `app-store-server-library`. On verification failure the response SHALL be HTTP 401. On success the backend SHALL apply the notification to the matching `Subscription` row (keyed by `originalTransactionId` from the decoded payload) and respond HTTP 200.

#### Scenario: REFUND notification revokes the subscription
- **WHEN** Apple posts a verified `REFUND` notification for a known `originalTransactionId`
- **THEN** that `Subscription` row's `status` becomes `'revoked'` AND the response is HTTP 200

#### Scenario: DID_RENEW notification extends expiry
- **WHEN** Apple posts a verified `DID_RENEW` notification with a new `expiresDate`
- **THEN** the matching `Subscription` row's `expiresAt` is updated AND `status` becomes `'active'`

#### Scenario: EXPIRED notification marks the row expired
- **WHEN** Apple posts a verified `EXPIRED` notification
- **THEN** the matching `Subscription` row's `status` becomes `'expired'`

#### Scenario: Unknown notification type is ack'd
- **WHEN** Apple posts a verified notification whose `notificationType` is unrecognised
- **THEN** the backend logs it and responds HTTP 200 (no error, no row update)

#### Scenario: Unverified signature is rejected
- **WHEN** the endpoint receives a `signedPayload` whose signature fails verification
- **THEN** the response is HTTP 401

#### Scenario: Notification for unknown originalTransactionId is ack'd
- **WHEN** Apple posts a verified notification for an `originalTransactionId` not present in the database
- **THEN** the backend logs it and responds HTTP 200 (it will be created the next time the client verifies)

### Requirement: Verifier configuration is environment-driven
The backend SHALL read `APPLE_BUNDLE_ID`, `APPLE_ENVIRONMENT` (`Sandbox` or `Production`), `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, and `APPLE_PRIVATE_KEY_PATH` from environment variables. The `SignedDataVerifier` SHALL be instantiated with these values plus Apple's bundled root certificates. The same verifier SHALL be reused for both transaction verification and notification verification.

#### Scenario: Missing environment variable fails fast at startup
- **WHEN** the backend starts without `APPLE_BUNDLE_ID` set
- **THEN** startup fails with a clear error message
