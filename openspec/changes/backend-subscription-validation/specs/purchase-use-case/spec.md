## MODIFIED Requirements

### Requirement: refreshEntitlements verifies entitlements against the backend
`PurchaseUseCase.refreshEntitlements()` SHALL iterate `Transaction.currentEntitlements`, and for each `VerificationResult.verified` entry SHALL POST the `jwsRepresentation` to `SubscriptionService.verify(signedTransaction:)`. The method SHALL OR the `isPro` field across all responses and write the final value to both `self.isPro` and the `UserDefaults` cache. If any network error is thrown while verifying, the method SHALL return without modifying `self.isPro` so the previously cached value is preserved.

#### Scenario: Active subscription confirmed by backend
- **WHEN** the user has one active sandbox entitlement AND the backend returns `{ isPro: true, ... }` for it
- **THEN** `self.isPro` becomes `true` AND `userDefaultsStore.setBool(true, for: .isPro)` is called

#### Scenario: Backend reports not Pro
- **WHEN** the user has one entitlement AND the backend returns `{ isPro: false, ... }` (e.g. the row was revoked server-side)
- **THEN** `self.isPro` becomes `false` AND the cache is updated to `false`

#### Scenario: Network failure preserves cached value
- **WHEN** `refreshEntitlements()` is called offline (or the backend is unreachable) AND the cached `isPro` is `true`
- **THEN** `self.isPro` remains `true` AND no `false` is written to the cache

#### Scenario: No entitlements ⇒ isPro becomes false
- **WHEN** `Transaction.currentEntitlements` yields no verified transactions AND the backend was reachable
- **THEN** `self.isPro` becomes `false` AND the cache is updated to `false`

#### Scenario: Unverified entitlement is skipped
- **WHEN** `Transaction.currentEntitlements` yields a `.unverified` result
- **THEN** the method SHALL skip that entry without posting to the backend

#### Scenario: Multiple entitlements OR to true
- **WHEN** the user has two entitlements AND at least one verify response has `isPro: true`
- **THEN** `self.isPro` becomes `true`

### Requirement: PurchaseUseCase depends on SubscriptionService
`PurchaseUseCase` SHALL declare `@ObservationIgnored @Injected(\.subscriptionService) private var subscriptionService` and SHALL invoke it exclusively from `refreshEntitlements()`. No other method on `PurchaseUseCase` SHALL talk to `SubscriptionService` directly. The `SubscriptionService` SHALL be registered in `Container+App.swift` as a singleton.

#### Scenario: DI container wires SubscriptionService
- **WHEN** the app launches and Factory resolves `PurchaseUseCase`
- **THEN** `subscriptionService` is injected from `Container.shared.subscriptionService()`

### Requirement: Cached isPro is the offline fallback
`PurchaseUseCase.init()` SHALL initialise `isPro` from `userDefaultsStore.bool(for: .isPro, defaultingTo: false)` before any backend call, and SHALL trigger `Task { await refreshEntitlements() }` for asynchronous reconciliation. The cache write SHALL happen only inside `refreshEntitlements()` after a successful backend round-trip — never from `purchase(_:)` or `restorePurchases()` directly.

#### Scenario: App launches offline with cached Pro
- **WHEN** the app launches with `UserDefaults` `isPro = true` AND the network is unreachable
- **THEN** `purchaseUseCase.isPro` is `true` immediately after `init()` AND remains `true` after the failed `refreshEntitlements()` call

#### Scenario: App launches with no cache
- **WHEN** the app launches for the first time (no `isPro` key in `UserDefaults`)
- **THEN** `purchaseUseCase.isPro` is `false` until the first successful `refreshEntitlements()` resolves

## ADDED Requirements

### Requirement: SubscriptionService posts signed transactions to the backend
The iOS app SHALL define `SubscriptionServiceProtocol` with one method: `verify(signedTransaction: String) async throws -> SubscriptionVerifyResponse`. The concrete `SubscriptionService` SHALL be a thin Service — it constructs the path, encodes the body, calls `networkClient.post(...)`, and rethrows a typed `SubscriptionError` via a `private static mapVerifyError(_:)`. It SHALL NOT cache, branch, retry, or hold state.

#### Scenario: Verify sends the JWS as JSON body
- **WHEN** `subscriptionService.verify(signedTransaction: "ey...")` is called
- **THEN** the service POSTs `{ "signedTransaction": "ey..." }` to `/api/subscriptions/verify`

#### Scenario: 401 maps to SubscriptionError.unauthorized
- **WHEN** the network client returns a 401
- **THEN** the service throws `SubscriptionError.unauthorized`

#### Scenario: 400 maps to SubscriptionError.invalidTransaction
- **WHEN** the network client returns a 400
- **THEN** the service throws `SubscriptionError.invalidTransaction`

#### Scenario: Other failures map to SubscriptionError.verificationFailed
- **WHEN** the network client throws any other error (timeout, 5xx, decoding)
- **THEN** the service throws `SubscriptionError.verificationFailed`

### Requirement: SubscriptionError conforms to UserFacingError
The app SHALL define `enum SubscriptionError: UserFacingError, Equatable` with cases `unauthorized`, `invalidTransaction`, `verificationFailed`, each exposing a human-readable `errorTitle` and `errorDescription`. The enum SHALL live at `Domain/Errors/SubscriptionError.swift`.

#### Scenario: Error renders into ErrorInfo
- **WHEN** a ViewModel constructs `ErrorInfo(SubscriptionError.verificationFailed)`
- **THEN** the resulting `ErrorInfo.title` and `ErrorInfo.description` come from the enum case
