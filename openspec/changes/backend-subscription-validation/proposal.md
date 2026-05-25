## Why

`PurchaseUseCase` currently treats the device as the sole authority on Pro entitlement: `refreshEntitlements()` reads `Transaction.currentEntitlements` from StoreKit and writes `isPro` directly. This is the standard subscription-fraud vector for iOS apps — jailbroken devices can fabricate entitlements, and revoked/refunded subscriptions only clear on the device when Apple's StoreKit happens to push an update. There is no server-side record of who is Pro, so backend endpoints cannot gate Pro-only resources, and customer-support refund handling is invisible to the app until the device reconciles.

This change moves the source of truth for Pro entitlement to the backend, verified against Apple's App Store Server API using the signed JWS payload that `Transaction.currentEntitlements` already produces. The device still drives the UX (purchase flow, restore button), but `isPro` is set from the server's response.

## What Changes

- **Backend: new Prisma model** `Subscription` with `userId`, `productId`, `originalTransactionId` (unique), `expiresAt`, `status` (`active` / `expired` / `revoked` / `in_grace_period`), `environment` (`Sandbox` / `Production`), `lastVerifiedAt`
- **Backend: new endpoint** `POST /api/subscriptions/verify` — accepts `{ signedTransaction: String }` (the JWS from `VerificationResult.jwsRepresentation`), verifies the signature against Apple's root certificates, decodes the payload, upserts the `Subscription` row by `originalTransactionId`, and returns `{ isPro: Bool, expiresAt: ISO8601?, productId: String? }`
- **Backend: new endpoint** `POST /api/subscriptions/notifications` — webhook for App Store Server Notifications V2; verifies the signed payload, applies `REFUND` / `EXPIRED` / `REVOKE` / `DID_RENEW` / `GRACE_PERIOD_EXPIRED` updates to the matching `Subscription` row
- **Backend: extend** `GET /api/me` (or equivalent profile endpoint) with `isPro: Bool` and `proExpiresAt: ISO8601?`, computed from the user's `Subscription` rows (`isPro = true` iff any row has `status` ∈ {`active`, `in_grace_period`} and `expiresAt > now`)
- **Backend: dependency** add `@apple/app-store-server-library` for JWS verification and notification decoding
- **iOS: new** `SubscriptionService` + protocol — thin Service wrapping `POST /api/subscriptions/verify`, returns `SubscriptionVerifyResponse`
- **iOS: new** wire models `SubscriptionVerifyBody`, `SubscriptionVerifyResponse` in `Networking/Models/`
- **iOS: new** typed feature error `SubscriptionError: UserFacingError` in `Domain/Errors/`
- **iOS: modify** `PurchaseUseCase.refreshEntitlements()` — for each verified `Transaction` from `Transaction.currentEntitlements`, post its `jwsRepresentation` to `SubscriptionService.verify(...)`; OR the responses into `isPro`. The `Transaction.updates` listener follows the same flow.
- **iOS: modify** `PurchaseUseCase.purchase(_:)` — after `transaction.finish()`, call `refreshEntitlements()` (already does so today) so the new code path verifies the just-purchased transaction with the backend before returning `.success`
- **iOS: keep** `UserDefaultsStore` caching of `isPro` — used only as the offline / pre-fetch fallback. On launch, `isPro` initialises from the cached value, then `refreshEntitlements()` overwrites it from the backend.

**Unchanged:**
- `PurchaseUseCaseProtocol` public surface — `isPro: Bool`, `loadProducts()`, `purchase(_:)`, `restorePurchases()`, `refreshEntitlements()` signatures all stay
- `PaywallViewModel`, `AccountViewModel`, and all `isPro`-gated UI — they read `purchaseUseCase.isPro` unchanged
- StoreKit IO (`Product.products`, `product.purchase()`, `AppStore.sync()`, `Transaction.updates`) — still inlined in `PurchaseUseCase`, per the "single-consumer device frameworks stay inlined" rule

## Capabilities

### New Capabilities

- `subscriptions-api`: Backend endpoints `POST /api/subscriptions/verify` (JWS verification + upsert) and `POST /api/subscriptions/notifications` (App Store Server Notifications V2 webhook); Prisma `Subscription` model; `isPro` / `proExpiresAt` exposed on the profile endpoint

### Modified Capabilities

- `purchase-use-case`: `PurchaseUseCase.refreshEntitlements()` posts each `Transaction.currentEntitlements` JWS to the backend and sets `isPro` from the server response; `SubscriptionService` injected via DI; `UserDefaults` cache of `isPro` becomes the offline fallback only

## Impact

**Backend files modified:**
- `prisma/schema.prisma` — add `Subscription` model
- `prisma/seed.ts` — no seed data (subscriptions are user-generated); only schema migration
- `src/routes/subscriptions.ts` — new route file (verify + notifications endpoints)
- `src/routes/profile.ts` (or wherever `/api/me` lives) — add `isPro`, `proExpiresAt` to response
- `src/services/appleVerifier.ts` — new thin wrapper around `@apple/app-store-server-library`
- `src/index.ts` — mount subscriptions router
- `package.json` — add `@apple/app-store-server-library` dependency
- `.env.example` — add `APPLE_BUNDLE_ID`, `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` (path or inline), `APPLE_ENVIRONMENT`

**iOS files modified:**
- `FocusOnYourself/Domain/UseCases/Purchase/PurchaseUseCase.swift` — `refreshEntitlements()` posts JWS to backend
- `FocusOnYourself/App/Container+App.swift` — register `subscriptionService` under `// MARK: - Services`

**iOS files added:**
- `FocusOnYourself/Services/Subscription/SubscriptionServiceProtocol.swift`
- `FocusOnYourself/Services/Subscription/SubscriptionService.swift`
- `FocusOnYourself/Networking/Models/SubscriptionVerifyBody.swift`
- `FocusOnYourself/Networking/Models/SubscriptionVerifyResponse.swift`
- `FocusOnYourself/Domain/Errors/SubscriptionError.swift`

**No changes to:**
- `PurchaseUseCaseProtocol.swift` (interface unchanged)
- `PaywallViewModel.swift`, `AccountViewModel.swift`
- `ProductID.swift`, `PurchaseOutcome.swift`, `PurchaseError.swift`
- `FocusOnYourselfStoreKit.storekit` (local test config)
