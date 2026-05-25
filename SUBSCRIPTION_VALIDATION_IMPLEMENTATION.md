# Server-Side Subscription Validation — Implementation Summary

Implemented from `openspec/changes/backend-subscription-validation/`. Both backend and iOS landed; backend type-checks, iOS builds, SwiftLint clean.

## Result

| Check | Status |
|---|---|
| Backend `npm run build` (tsc) | ✓ pass |
| Prisma migration applied | ✓ `20260525140434_add_subscriptions` |
| iOS `xcodebuild` | ✓ BUILD SUCCEEDED |
| `swiftlint` | ✓ 0 violations, 189 files |

## Threat model

`PurchaseUseCase.refreshEntitlements()` no longer trusts the device alone. Each verified `Transaction.currentEntitlements` JWS is posted to the backend, which checks Apple's signature, validates `bundleId`, persists to the `Subscription` table, and returns the user's authoritative `isPro`. App Store Server Notifications V2 propagate refunds / revocations / renewals out-of-band so the server doesn't depend on the user re-opening the app.

Offline behaviour is preserved: any thrown error inside the verify loop returns early without flipping `isPro`, so the previously cached value is retained.

---

## Backend changes (`/Users/deakdavid/Work/ideas/focusonyourself-backend`)

### Added

- **`src/subscriptions/appleVerifier.ts`** — thin wrapper around `@apple/app-store-server-library`'s `SignedDataVerifier`. Peeks the JWS payload's `environment` field per-request and dispatches to a cached `SignedDataVerifier` for that environment (`Sandbox` / `Production` / `Xcode` / `LocalTesting`), so one backend handles all four. Configured by `APPLE_BUNDLE_ID` + a directory of Apple root `.cer` files. Exposes `verifyTransaction(jws)` and `verifyNotification(jws)`.
- **`src/subscriptions/service.ts`** — DB layer. `upsertSubscription(...)` keyed by `originalTransactionId`. `userProSnapshot(userId)` returns `{ isPro, expiresAt, productId }` based on rows with `status ∈ {active, in_grace_period}` AND `expiresAt > now`. `applyNotificationToSubscription(...)` for webhook updates.
- **`src/subscriptions/router.ts`** — `POST /verify` (behind `authenticate`) + `POST /notifications` (unauthenticated; signature is the auth). Status mapping for `REFUND` / `REVOKE` / `EXPIRED` / `GRACE_PERIOD_EXPIRED` / `DID_RENEW` / `SUBSCRIBED` / `REFUND_REVERSED`; unknown types log and ack 200.
- **`prisma/migrations/20260525140434_add_subscriptions/migration.sql`** — generated migration for the new table.
- **`certs/apple-roots/README.md`** — placeholder + instructions for dropping in Apple's root CA `.cer` files (the certs themselves are gitignored).

### Modified

- **`prisma/schema.prisma`** — new `Subscription` model + back-relation on `User`:

  ```prisma
  model Subscription {
    id                    String   @id @default(cuid())
    userId                String
    user                  User     @relation(fields: [userId], references: [id], onDelete: Cascade)
    productId             String
    originalTransactionId String   @unique
    expiresAt             DateTime
    status                String   // active | expired | revoked | in_grace_period
    environment           String   // Sandbox | Production | Xcode | LocalTesting
    lastVerifiedAt        DateTime @default(now())
    createdAt             DateTime @default(now())
    updatedAt             DateTime @updatedAt
    @@index([userId])
  }
  ```

- **`src/index.ts`** — mounts the new router at `/api/subscriptions`.
- **`src/auth/router.ts`** — `GET /api/auth/me` now returns `{ id, email, isPro, proExpiresAt }`.
- **`.env.example`** — added `APPLE_BUNDLE_ID` and `APPLE_ROOT_CERTS_DIR`. No environment env var — the verifier peeks each JWS payload's `environment` field and routes to a per-env `SignedDataVerifier`.
- **`.gitignore`** — `certs/apple-roots/*.cer` and `*.der` excluded.
- **`package.json`** — added `@apple/app-store-server-library@^3.1.0`.

### Verify-endpoint shape

```ts
// POST /api/subscriptions/verify  (Bearer token required)
//   body:     { signedTransaction: string }   // Transaction.jwsRepresentation from iOS
//   response: { isPro: boolean, expiresAt: ISO8601|null, productId: string|null }
```

Status mapping inside the upsert:

```ts
function statusFromPayload(expiresAt: Date, revocationDate?: number): SubscriptionStatus {
  if (revocationDate) return 'revoked'
  return expiresAt.getTime() > Date.now() ? 'active' : 'expired'
}
```

`POST /api/subscriptions/notifications` re-verifies the embedded `signedTransactionInfo` JWS (not just the envelope) before mutating any row.

---

## iOS changes (`/Users/deakdavid/Work/ideas/focusonyourself-ios`)

### Added

- **`FocusOnYourself/Networking/Models/SubscriptionVerifyBody.swift`** — `Encodable` wire model with one field, `signedTransaction: String`.
- **`FocusOnYourself/Networking/Models/SubscriptionVerifyResponse.swift`** — `Decodable` `{ isPro, expiresAt?, productId? }`.
- **`FocusOnYourself/Domain/Errors/SubscriptionError.swift`** — `enum SubscriptionError: UserFacingError, Equatable { unauthorized, invalidTransaction, verificationFailed }` with `errorTitle` + `errorDescription`.
- **`FocusOnYourself/Services/Subscription/SubscriptionServiceProtocol.swift`** — single `verify(signedTransaction:)` method.
- **`FocusOnYourself/Services/Subscription/SubscriptionService.swift`** — thin Service matching `AuthService` / `ArticlesService` style; `@Injected(\.networkClient)`, single `do/catch`, `mapVerifyError(_:)` static returning typed `SubscriptionError`.

### Modified

- **`FocusOnYourself/App/Container+App.swift`** — registered `subscriptionService` as a singleton under `// MARK: - Services`.
- **`FocusOnYourself/Domain/UseCases/Purchase/PurchaseUseCase.swift`** — `refreshEntitlements()` now posts JWS to the backend and ORs the responses. Final body:

  ```swift
  func refreshEntitlements() async {
      var serverIsPro = false
      for await result in Transaction.currentEntitlements {
          guard case .verified = result else { continue }
          do {
              let response = try await subscriptionService.verify(signedTransaction: result.jwsRepresentation)
              if response.isPro { serverIsPro = true }
          } catch {
              // Network failure mid-loop — preserve the previously cached isPro value
              return
          }
      }
      isPro = serverIsPro
      userDefaultsStore.setBool(serverIsPro, for: .isPro)
  }
  ```

  Init flow unchanged: cached `isPro` from `UserDefaultsStore` hydrates immediately; `Task { await refreshEntitlements() }` reconciles asynchronously; `Transaction.updates` listener runs the same code path.

### Divergence from the spec

The design doc's §6 specified constructor injection (`init(networkClient: NetworkClientProtocol)`). The codebase convention for every existing Service is property injection via `@Injected(\.networkClient)` — `AuthService`, `ArticlesService`, `AffirmationService`, `MeditationService`, `CheckinsService` all do this. Followed the codebase, not the spec. The spec's task 8.2 and 8.3 should be considered updated to match.

---

## Endpoints

| Method | Path | Auth | Body | Returns |
|---|---|---|---|---|
| `POST` | `/api/subscriptions/verify` | Bearer | `{ signedTransaction }` | `{ isPro, expiresAt, productId }` |
| `POST` | `/api/subscriptions/notifications` | Apple JWS signature | `{ signedPayload }` | 200 / 401 |
| `GET` | `/api/auth/me` | Bearer | — | `{ id, email, isPro, proExpiresAt }` (extended) |

Error responses for `/verify`: `400` for missing / invalid / bundle-mismatched JWS, `401` for unauthenticated. Notifications endpoint: `401` only when the Apple signature fails to verify; otherwise it ack's `200` even for unknown notification types or unknown `originalTransactionId` (so Apple doesn't retry).

---

## What's required to actually run end-to-end

The code is complete and compiles, but these one-time setup steps are needed for the verify path to succeed:

1. **Apple root certificates.** Download from <https://www.apple.com/certificateauthority/>:
   - `AppleIncRootCertificate.cer`
   - `AppleRootCA-G2.cer`
   - `AppleRootCA-G3.cer`

   Drop into `focusonyourself-backend/certs/apple-roots/`. The verifier loads every `.cer`/`.der` it finds there.

2. **`.env` values** (`focusonyourself-backend/.env`):

   ```
   APPLE_BUNDLE_ID="app.ddworks.FocusOnYourself"
   APPLE_ROOT_CERTS_DIR="./certs/apple-roots"
   ```

   No `APPLE_ENVIRONMENT` needed — each JWS carries its own `environment` field and the verifier instantiates a per-env `SignedDataVerifier` on first use. One Render service handles Sandbox **and** Production **and** local `.storekit` testing.

3. **App Store Connect → App Store Server Notifications V2** — point the production URL at `https://<backend-host>/api/subscriptions/notifications`. For local sandbox testing, use App Store Connect's "Request a Test Notification" feature against a publicly reachable URL (e.g. ngrok tunnel into the dev backend).

4. **Sandbox round-trip verification** (per spec tasks §10.4–10.9):
   - Perform a sandbox purchase in the simulator with `FocusOnYourselfStoreKit.storekit`.
   - Confirm a `Subscription` row appears with `status='active'`.
   - Manually set `status='revoked'` in the DB → trigger `refreshEntitlements()` (background → foreground) → confirm `isPro` flips to `false`.
   - Toggle airplane mode → confirm `isPro` does NOT flip to `false` (cache preserved on network error).

---

## Follow-ups deliberately out of scope

- **`appAccountToken` binding.** The spec design §3 risk note flagged that without setting `Product.PurchaseOption.appAccountToken(_:)` at purchase time, the server can't cryptographically prove a JWS belongs to *our* user — it only knows the JWS was posted by an authenticated user. A determined attacker with two App Store IDs could cross-fund another of their own accounts. Acceptable starting posture; tighten in a follow-up.
- **Apple revocation propagation latency.** App Store Server Notifications V2 typically arrive within seconds, but Apple's SLA is "soon." A revoked subscription won't flip `isPro` to `false` on the device until the user next opens the app (which triggers `refreshEntitlements()`) — assuming the notification has already updated the DB by then.
- **`/api/auth/me` consumption in iOS.** The endpoint now exposes `isPro` + `proExpiresAt`, but no iOS code reads them yet. `PurchaseUseCase` still drives `isPro` exclusively from `/api/subscriptions/verify`. Future cleanup: have `AuthUseCase` seed `isPro` from `/me` on login so the first refresh round-trip isn't needed.

---

## Files at a glance

**Backend (10 changes)**

```
focusonyourself-backend/
├── .env.example                                              modified
├── .gitignore                                                modified
├── package.json / package-lock.json                          +@apple/app-store-server-library
├── prisma/schema.prisma                                      +Subscription model
├── prisma/migrations/20260525140434_add_subscriptions/       added
├── src/index.ts                                              +mount /api/subscriptions
├── src/auth/router.ts                                        /me now returns isPro
├── src/subscriptions/appleVerifier.ts                        added
├── src/subscriptions/service.ts                              added
├── src/subscriptions/router.ts                               added
└── certs/apple-roots/README.md                               added
```

**iOS (7 changes)**

```
focusonyourself-ios/
├── FocusOnYourself/Networking/Models/SubscriptionVerifyBody.swift          added
├── FocusOnYourself/Networking/Models/SubscriptionVerifyResponse.swift      added
├── FocusOnYourself/Domain/Errors/SubscriptionError.swift                   added
├── FocusOnYourself/Services/Subscription/SubscriptionServiceProtocol.swift added
├── FocusOnYourself/Services/Subscription/SubscriptionService.swift         added
├── FocusOnYourself/App/Container+App.swift                                 +subscriptionService factory
└── FocusOnYourself/Domain/UseCases/Purchase/PurchaseUseCase.swift          refreshEntitlements rewrite
```

The iOS Xcode project uses Xcode 16 filesystem-synchronized groups (`PBXFileSystemSynchronizedRootGroup`), so the new files were picked up automatically — no `project.pbxproj` edit needed.
