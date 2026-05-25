## 1. Backend — Prisma Schema

- [ ] 1.1 Add `Subscription` model to `prisma/schema.prisma` with fields per design §2; relate to `User`
- [ ] 1.2 Run `DATABASE_URL="file:./prisma/dev.db" npx prisma migrate dev --name add-subscriptions` to generate and apply the migration
- [ ] 1.3 Run `DATABASE_URL="file:./prisma/dev.db" npx prisma generate` to regenerate the Prisma client

## 2. Backend — Apple Verifier Wrapper

- [ ] 2.1 `npm install @apple/app-store-server-library`
- [ ] 2.2 Create `src/services/appleVerifier.ts` — exports `verifyTransaction(jws)` and `verifyNotification(jws)`, instantiates `SignedDataVerifier` with `APPLE_BUNDLE_ID`, `APPLE_ENVIRONMENT`, loaded root certs
- [ ] 2.3 Add `.env.example` keys: `APPLE_BUNDLE_ID`, `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY_PATH`, `APPLE_ENVIRONMENT` (`Sandbox` | `Production`)
- [ ] 2.4 Document where to obtain each value in the backend README (App Store Connect → Keys, Bundle ID from project)

## 3. Backend — Verify Endpoint

- [ ] 3.1 Create `src/routes/subscriptions.ts` with `POST /verify` handler
- [ ] 3.2 Apply `requireAuth` middleware so `req.user.id` is available
- [ ] 3.3 Parse `{ signedTransaction: String }` body; return HTTP 400 if missing or not a string
- [ ] 3.4 Call `verifyTransaction(signedTransaction)`; return HTTP 400 if JWS verification throws
- [ ] 3.5 Validate `payload.bundleId === APPLE_BUNDLE_ID`; return HTTP 400 if mismatched
- [ ] 3.6 Upsert `Subscription` by `originalTransactionId` per design §3
- [ ] 3.7 Compute `isUserPro(userId)` — any subscription row for the user with `status ∈ {active, in_grace_period}` AND `expiresAt > now`
- [ ] 3.8 Return `{ isPro, expiresAt, productId }` where `expiresAt`/`productId` come from the most recent active row (or `null` if not Pro)
- [ ] 3.9 Mount router in `src/index.ts` at `/api/subscriptions`

## 4. Backend — Notifications Endpoint

- [ ] 4.1 Add `POST /notifications` handler to `src/routes/subscriptions.ts` — unauthenticated (Apple posts to it)
- [ ] 4.2 Parse `{ signedPayload: String }` body
- [ ] 4.3 Call `verifyNotification(signedPayload)`; return HTTP 401 if verification throws
- [ ] 4.4 Switch on `payload.notificationType`: `REFUND` / `REVOKE` → `status = 'revoked'`; `EXPIRED` → `status = 'expired'`; `DID_RENEW` → update `expiresAt`, `status = 'active'`; `GRACE_PERIOD_EXPIRED` → `status = 'expired'`
- [ ] 4.5 Unknown notification types: log and respond HTTP 200 (Apple retries non-200)
- [ ] 4.6 Update the matching `Subscription` row by `originalTransactionId`; if no row exists, log and respond HTTP 200 (we'll learn about it on next client verify)
- [ ] 4.7 Document the production webhook URL in App Store Connect → App → App Information → App Store Server Notifications V2

## 5. Backend — Profile Endpoint Extension

- [ ] 5.1 Extend the existing `/api/me` (or equivalent) response with `isPro: Bool` and `proExpiresAt: ISO8601?`
- [ ] 5.2 Compute via the same `isUserPro(userId)` helper used by `/verify`
- [ ] 5.3 Add a corresponding test or curl example to the README

## 6. Backend — Verify

- [ ] 6.1 `npm run build`
- [ ] 6.2 `docker compose up --build`
- [ ] 6.3 With a valid sandbox JWS from a paired iOS run, `curl -X POST localhost:3005/api/subscriptions/verify -H "Authorization: Bearer <token>" -H "Content-Type: application/json" -d '{"signedTransaction":"..."}'` returns `{ isPro: true, ... }`
- [ ] 6.4 Posting the same JWS twice returns the same response and does not duplicate the `Subscription` row
- [ ] 6.5 Posting an invalid / tampered JWS returns HTTP 400
- [ ] 6.6 Posting a JWS with a different `bundleId` returns HTTP 400
- [ ] 6.7 Apple "Request a Test Notification" produces a `TEST` notification that hits `/api/subscriptions/notifications` and returns HTTP 200

## 7. iOS — Wire Models and Error

- [ ] 7.1 Create `Networking/Models/SubscriptionVerifyBody.swift` — `struct SubscriptionVerifyBody: Codable { let signedTransaction: String }`
- [ ] 7.2 Create `Networking/Models/SubscriptionVerifyResponse.swift` — `struct SubscriptionVerifyResponse: Codable { let isPro: Bool; let expiresAt: Date?; let productId: String? }`
- [ ] 7.3 Create `Domain/Errors/SubscriptionError.swift` — `enum SubscriptionError: UserFacingError, Equatable { case unauthorized, invalidTransaction, verificationFailed }` with `errorTitle` / `errorDescription`

## 8. iOS — SubscriptionService

- [ ] 8.1 Create `Services/Subscription/SubscriptionServiceProtocol.swift` — `protocol SubscriptionServiceProtocol { func verify(signedTransaction: String) async throws -> SubscriptionVerifyResponse }`
- [ ] 8.2 Create `Services/Subscription/SubscriptionService.swift` per design §6 — `final class`, injects `networkClient`, single `do/catch` + `mapVerifyError(_:)` static
- [ ] 8.3 Register in `Container+App.swift` under `// MARK: - Services`: `var subscriptionService: Factory<SubscriptionServiceProtocol> { self { @MainActor in SubscriptionService(networkClient: self.networkClient()) }.singleton }`

## 9. iOS — PurchaseUseCase Rewrite

- [ ] 9.1 Add `@ObservationIgnored @Injected(\.subscriptionService) private var subscriptionService` to `PurchaseUseCase`
- [ ] 9.2 Rewrite `refreshEntitlements()` per design §5 — iterate `Transaction.currentEntitlements`, post each verified result's `jwsRepresentation` to `subscriptionService.verify(...)`, OR the responses, update `self.isPro`
- [ ] 9.3 On any thrown error inside the loop, return without touching `self.isPro` so the cached value persists
- [ ] 9.4 Confirm `init()` still reads cached `isPro` from `userDefaultsStore` first, then triggers `Task { await refreshEntitlements() }`
- [ ] 9.5 Confirm `Transaction.updates` listener still calls `refreshEntitlements()` on every update
- [ ] 9.6 Confirm `purchase(_:)` still calls `refreshEntitlements()` after `transaction.finish()`

## 10. iOS — Build and Verify

- [ ] 10.1 `xcodebuild -project FocusOnYourself.xcodeproj -scheme FocusOnYourself -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20` — no errors
- [ ] 10.2 `swiftlint --fix && swiftlint` — no violations
- [ ] 10.3 Run app in simulator with `FocusOnYourselfStoreKit.storekit` config and backend running locally
- [ ] 10.4 Perform a sandbox monthly purchase from the Paywall — confirm backend creates a `Subscription` row with `status = 'active'`
- [ ] 10.5 Confirm `isPro` flips to `true` in the app after the purchase completes
- [ ] 10.6 Force-quit and relaunch — confirm `isPro` is still `true` (cache restored, then backend confirms)
- [ ] 10.7 In a DB client, change the row to `status = 'revoked'`; trigger `refreshEntitlements()` (e.g. via background → foreground); confirm `isPro` flips to `false`
- [ ] 10.8 Disable network on the simulator; confirm `isPro` does NOT flip to `false` on next `refreshEntitlements()` (network error → preserve cache)
- [ ] 10.9 Tap "Restore Purchases" — confirm `AppStore.sync()` runs, then the entitlements re-verify with the backend

## 11. iOS — Observability

- [ ] 11.1 Add a `#if DEBUG` log in `refreshEntitlements()` showing each verify response — useful while iterating, removed before release
- [ ] 11.2 Confirm `ErrorInfo` is NOT surfaced to the user on background `refreshEntitlements()` failures — silent fallback to cache
