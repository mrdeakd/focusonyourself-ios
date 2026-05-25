## Context

`PurchaseUseCase` is iOS 17+, which means `Transaction.currentEntitlements` and `VerificationResult.verified` already produce a JWS signed by Apple. The JWS is everything the backend needs: bundle ID, original transaction ID, product ID, expiration, environment, signed by Apple's leaf certificate chain. The modern App Store Server API path (verify the JWS) is preferred over the legacy `verifyReceipt` endpoint — Apple has deprecated `verifyReceipt` and `app-store-server-library` is the canonical replacement.

Apple's `app-store-server-library-node` package gives us `SignedDataVerifier` which validates the JWS against Apple's root certificates and returns a decoded `JWSTransactionDecodedPayload`. The same library decodes Server Notifications V2.

Today `refreshEntitlements()` is called on init, on every `Transaction.updates` tick, and after a successful purchase. None of these change — only what happens **inside** `refreshEntitlements()` changes.

## Goals / Non-Goals

**Goals:**
- Backend is the source of truth for `isPro`; iOS trusts the server response over local entitlements
- `Subscription` Prisma model keyed by `originalTransactionId` so refunds, renewals, and re-subscriptions all converge on the same row
- App Store Server Notifications V2 webhook so refunds / family-sharing revocations propagate without the user opening the app
- Offline behaviour: `isPro` remains correct based on the last-known cached value when the device is offline; we never block UI on the backend
- `PurchaseUseCaseProtocol` and all call sites stay binary-compatible

**Non-Goals:**
- Legacy `verifyReceipt` (StoreKit 1 base64 receipt) support — we're iOS 17+ and StoreKit 2 only
- Family Sharing entitlement modelling beyond what App Store Server Notifications already gives us
- Promotional offers / introductory pricing logic — orthogonal; backend just records what Apple verified
- Server-side product catalog — `loadProducts()` still talks to StoreKit directly because Apple owns localised pricing
- Migrating already-active subscribers — first launch with the new build runs `refreshEntitlements()` and creates their `Subscription` row from `Transaction.currentEntitlements`, so no offline migration step needed

## Decisions

### 1. Use `@apple/app-store-server-library` for JWS verification — not custom JWT verification

Apple publishes an official Node library that knows about the root certs, the JWS structure, the typed payload, and the App Store Server Notifications V2 envelope. Rolling our own JWS verification means tracking Apple's certificate rotations manually — a maintenance burden that buys nothing.

```typescript
const verifier = new SignedDataVerifier(
  appleRootCertificates,
  /* enableOnlineChecks */ false,
  environment,
  process.env.APPLE_BUNDLE_ID!
)
const payload = await verifier.verifyAndDecodeTransaction(signedTransaction)
```

*Alternatives considered:* `jose` / `node-jsonwebtoken` with manual cert pinning — works but reinvents what Apple already ships and tests.

### 2. `originalTransactionId` is the canonical key — not `transactionId`

A single subscriber may have many `transactionId` values over time (one per renewal), but `originalTransactionId` is stable across the lifetime of the subscription. Keying the `Subscription` row by `originalTransactionId` means renewals UPDATE the same row instead of inserting new rows, and refunds / revocations can target a single row reliably.

```prisma
model Subscription {
  id                    Int      @id @default(autoincrement())
  userId                Int
  user                  User     @relation(fields: [userId], references: [id])
  productId             String
  originalTransactionId String   @unique
  expiresAt             DateTime
  status                String   // active | expired | revoked | in_grace_period
  environment           String   // Sandbox | Production
  lastVerifiedAt        DateTime @default(now())
  createdAt             DateTime @default(now())
  updatedAt             DateTime @updatedAt
  @@index([userId])
}
```

`status` is a String column rather than a Prisma enum so we can extend it without a migration when Apple adds new notification types.

### 3. Verify endpoint is idempotent and authenticated

`POST /api/subscriptions/verify` runs inside the existing `requireAuth` middleware (same as every other authenticated endpoint). It accepts the JWS, verifies it against Apple, checks `payload.bundleId === APPLE_BUNDLE_ID`, then upserts by `originalTransactionId`. Multiple posts of the same JWS converge — no duplicate rows, no error.

```typescript
const payload = await verifier.verifyAndDecodeTransaction(signedTransaction)
if (payload.bundleId !== process.env.APPLE_BUNDLE_ID) return res.status(400).json({ error: 'bundle mismatch' })

await prisma.subscription.upsert({
  where: { originalTransactionId: payload.originalTransactionId! },
  create: {
    userId: req.user.id,
    productId: payload.productId!,
    originalTransactionId: payload.originalTransactionId!,
    expiresAt: new Date(payload.expiresDate!),
    status: payload.revocationDate ? 'revoked' : (new Date(payload.expiresDate!) > new Date() ? 'active' : 'expired'),
    environment: payload.environment!,
  },
  update: {
    expiresAt: new Date(payload.expiresDate!),
    status: payload.revocationDate ? 'revoked' : (new Date(payload.expiresDate!) > new Date() ? 'active' : 'expired'),
    lastVerifiedAt: new Date(),
  },
})
```

The response is computed from the user's full subscription state, not just the one row that was just upserted:

```typescript
const isPro = await isUserPro(req.user.id)  // any active|grace row with expiresAt > now
res.json({ isPro, expiresAt: ..., productId: ... })
```

*Alternatives considered:* Lock the row to the posting user only — works but means a family-shared subscription can have multiple rows for the same `originalTransactionId`. Apple's model is one-row-per-original-tx; we follow that.

### 4. App Store Server Notifications V2 webhook is unauthenticated but signature-verified

The notifications endpoint is the public callback Apple posts to. It cannot use our auth middleware. Instead, it verifies the signed envelope using the same `SignedDataVerifier`. Without a valid Apple signature, the request is dropped with 401.

```typescript
const payload = await verifier.verifyAndDecodeNotification(signedPayload)
// payload.notificationType ∈ { REFUND, REVOKE, EXPIRED, DID_RENEW, GRACE_PERIOD_EXPIRED, ... }
```

A `REFUND` updates `status = 'revoked'`. `DID_RENEW` updates `expiresAt`. `EXPIRED` updates `status = 'expired'`. Unknown notification types are logged and ack'd 200 (Apple retries on non-200) — silently ignoring future Apple-added types is safer than failing them.

### 5. iOS posts every entitlement in `refreshEntitlements()`, ORs the results

`Transaction.currentEntitlements` is an async sequence; most users will have at most one active entitlement, but Family Sharing can produce more. The loop posts each verified transaction's JWS to the backend and ORs the `isPro` responses. The cached `UserDefaults` value is written from the final OR'd result.

```swift
func refreshEntitlements() async {
    var serverIsPro = false
    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else { continue }
        do {
            let response = try await subscriptionService.verify(signedTransaction: result.jwsRepresentation)
            if response.isPro { serverIsPro = true }
        } catch {
            // Network failure — leave isPro at its current cached value
            return
        }
    }
    self.isPro = serverIsPro
    userDefaultsStore.setBool(serverIsPro, for: .isPro)
}
```

The `return` on error preserves the cached value — we never downgrade a user to non-Pro because of a transient network blip.

### 6. `SubscriptionService` is a standard thin Service — no business logic

Follows the AffirmationService / ArticlesService pattern: one method, one `do/catch`, one `mapVerifyError(_:)` static. No retries, no fallbacks, no state.

```swift
final class SubscriptionService: SubscriptionServiceProtocol {
    private let networkClient: NetworkClientProtocol
    init(networkClient: NetworkClientProtocol) { self.networkClient = networkClient }

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
```

### 7. `SubscriptionVerifyResponse` is a flat wire model — no domain mapper

The response is consumed directly by `PurchaseUseCase`; there's no `Subscription` domain model (and no need for one — `isPro: Bool` and `expiresAt: Date?` are enough to drive every consumer). Per the model rules, no mapper is needed when wire == use site.

```swift
struct SubscriptionVerifyResponse: Codable {
    let isPro: Bool
    let expiresAt: Date?
    let productId: String?
}
```

`Date?` decoding follows the same convention as the rest of the wire layer (ISO8601 via `JSONDecoder.dateDecodingStrategy`).

## Risks / Trade-offs

**[Risk] Backend down on app launch ⇒ no Pro features even for paid users** → Mitigated by `UserDefaults` cache: `isPro` initialises from cache on launch, and any network failure inside `refreshEntitlements()` leaves the cache untouched. A user who was Pro yesterday stays Pro until we get a definitive "not pro" answer from the server.

**[Risk] Apple's signed JWS can be replayed by a malicious user from a separate Apple ID** → Each JWS includes `bundleId` and `appAccountToken`. We verify `bundleId` matches ours. `appAccountToken` (we'd need to set this at purchase time) would tie a transaction to our user — currently `purchase()` does not set it. **Out of scope for this change**; a follow-up should set `Product.PurchaseOption.appAccountToken(_:)` and validate on the server. For now, the row is bound to the posting user by `req.user.id`, which is fine for the common case but means a determined attacker with two App Store accounts could share entitlement with another of *their own* app accounts. Acceptable starting posture.

**[Risk] App Store Server Notifications V2 require a public HTTPS URL** → Production backend already serves over HTTPS; sandbox needs the URL configured in App Store Connect. Local dev uses Apple's "Request a Test Notification" button to drive the webhook manually.

**[Risk] `expiresAt` clock skew** → Apple's payload uses milliseconds-since-epoch from Apple's servers. We store as `DateTime` and compare against `new Date()` (server clock). Drift between Apple and our server is ≤ seconds in practice; we don't treat the boundary as adversarial.

**[Risk] StoreKit Testing Configuration (`FocusOnYourselfStoreKit.storekit`) produces JWS signed by Apple's local-test root, not the production root** → `SignedDataVerifier` accepts the StoreKit-test root certs when `environment === 'Sandbox'`. The library handles both; we just need to pass the right env. Documented in the `.env.example` as `APPLE_ENVIRONMENT=Sandbox` for dev / `Production` for prod.

**[Risk] First-time migration: existing Pro users on iCloud-cached `isPro=true`** → Handled organically. On first launch with the new build, `refreshEntitlements()` runs, fetches `Transaction.currentEntitlements`, posts each to the backend, creates their `Subscription` row, and the response continues to set `isPro=true`. No special migration step.

## Migration Plan

1. Backend: add `Subscription` model, generate migration, run locally
2. Backend: install `@apple/app-store-server-library`, add `appleVerifier.ts`
3. Backend: implement `POST /api/subscriptions/verify`, wire under `requireAuth`
4. Backend: extend `/api/me` with `isPro` + `proExpiresAt`
5. Backend: implement `POST /api/subscriptions/notifications`, deploy, verify with Apple's "Request a Test Notification" tool
6. iOS: add `SubscriptionService` + protocol + wire models + error
7. iOS: rewrite `PurchaseUseCase.refreshEntitlements()` to post JWS and trust backend
8. iOS: register `subscriptionService` in `Container+App.swift`
9. iOS: build (`xcodebuild ... | tail -20`), run in simulator with `.storekit` config, verify a sandbox purchase flows through the backend and `isPro` flips
10. iOS: manually toggle backend `Subscription.status = 'revoked'` for a test user, call `refreshEntitlements()`, verify `isPro` flips to `false`
