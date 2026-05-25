# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Git

Never add `Co-Authored-By: Claude` or any Claude authorship trailer to commit messages.

## Build & Lint

```bash
xcodebuild -project FocusOnYourself.xcodeproj -scheme FocusOnYourself \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20
swiftlint --fix && swiftlint   # also runs as an Xcode build phase
```

No unit tests. No Makefile/Fastfile — Xcode directly, or the `ios-app-release` skill.

**SwiftLint limits:** line 130 · file 400/500 · function 75 · closure 100/150.

**SwiftLint gotchas:**
- `empty_count` auto-rewrites `x.count > 0` → `!x.isEmpty`; for tuples/types without `.isEmpty`, suppress with `// swiftlint:disable:next empty_count`.
- `identifier_name` — `xs/sm/md/lg/xl/ys` are excluded as token names. Use full names (`dateString`, `checkIn`) for other shorts.
- `closure_body_length` — suppress `var body` overruns with `// swiftlint:disable:next closure_body_length` only after confirming sub-view extraction would harm readability.
- Swift Charts `BarMark.cornerRadius()` is NOT the deprecated `View.cornerRadius()` — suppress `legacy_constructor` only if flagged.

## Architecture

**MVVM + Use Cases + Calculators + Stores + Factory DI. iOS 17+, SwiftUI only.**

### Layers

| Layer | Location | Rule | May depend on |
|-------|----------|------|---------------|
| Screen | `Features/<F>/<Name>Screen.swift` | `@State private var viewModel = …ViewModel()` only — no state, no logic | ViewModel |
| ViewModel | `Features/<F>/<Name>ViewModel.swift` | `@Observable @MainActor final class`. All single-VM state + logic. Inlines device frameworks used only here. | Use Cases, Services, Calculators |
| Use Case | `Domain/UseCases/<F>/<Name>UseCase.swift` + protocol | **Shared** business logic (2+ VMs). `@Observable` if it holds reactive state. Inlines single-consumer device frameworks. | Services, Stores, Calculators, state-store Use Cases |
| Calculator | `Domain/Calculators/<Name>Calculator.swift` | Pure `struct`. No DI, no `@Observable`, no `@MainActor`, no `import SwiftUI`. All inputs are method args. | Nothing |
| Service | `Services/<D>/<Name>Service.swift` + protocol | **Network IO only.** Thin: encode → call → decode. No caching, branching, validation, state, or device frameworks. | `NetworkClient` |
| Store | `Stores/<D>/<Name>Store.swift` + protocol | Thin wrapper for one device-framework primitive. Same rules as Service. | The wrapped framework |
| Domain Model | `Domain/Models/<Name>.swift` | Plain `Codable` struct/enum, one type per file, no logic | Nothing |
| Wire Model | `Networking/Models/<Name>.swift` | Wire-format `Codable`, one type per file. Mapper extensions co-locate with the backend type. | Domain models |
| Design System | `DesignSystem/` | Tokens (`DS+Colors.swift`, `DS+Spacing.swift`, ...) | Nothing |
| Components | `Features/<F>/Components/` or `DesignSystem/Components/` | Reusable views in their own files | DS tokens, parent VM |

### Services — network only

Every Service method wraps the call in `do/catch` and rethrows a typed feature error via a `private static func map<Method>Error(_:)`:

```swift
func login(email: String, password: String) async throws -> AuthResponse {
    let path = "/api/auth/login"
    let body = LoginBody(email: email, password: password)
    do {
        let response: AuthResponse = try await networkClient.post(path, body: body)
        return response
    } catch {
        throw Self.mapLoginError(error)
    }
}

private static func mapLoginError(_ error: Error) -> AuthError {
    switch (error as? NetworkError)?.statusCode {
    case 401: .invalidCredentials
    default:  .signInFailed
    }
}
```

Shape inside the `do`: (1) `let path = "…"`, (2) zero-or-more `let` lines encoding params, (3) `let response: T = try await networkClient.<verb>(…)`, (4) `return response` (or `.compactMap { $0.toDomainModel() }` when wire ≠ domain). The trailing `catch { throw Self.map<Method>Error(error) }` is mandatory — one mapper per method, even when trivial (`{ .fetchFailed }`).

- One method = one network call. Multiple round-trips? Multiple methods, caller composes.
- Void POST: `let _: EmptyResponse = try await networkClient.post(path, body: body)`, no `return`.

**Typed errors.** Each feature has an `enum <Feature>Error: UserFacingError, Equatable` at `Domain/Errors/<Feature>Error.swift`, one type per file. `UserFacingError` exposes `errorTitle: String` and `errorDescription: String?`. Status-code branching lives only inside mappers; `NetworkError` never crosses out of `Services/`. VMs catch the typed error and use `ErrorInfo(error)`:

```swift
} catch let error as AuthError {
    self.error = ErrorInfo(error)
} catch {
    self.error = ErrorInfo(title: "Sign in failed", description: "Please try again.")
}
```

**Forbidden in a Service:** validation (`guard !x.isEmpty`), branching between paths (split into two methods), inline `Date.now`/runtime decisions (caller passes in), caching, retries, fallbacks, state, OR any device framework (`UserDefaults`, `Keychain`, `HealthKit`, `StoreKit`, `AVAudio`, `UNUserNotificationCenter`, `FoundationModels`).

**Two files per Service:** `<Name>ServiceProtocol.swift` + `<Name>Service.swift`. Plain `final class`, injects `networkClient` only. Registered as `Factory<<Name>ServiceProtocol>` in `Container+App.swift` under `// MARK: - Services`.

**Invariant:** `grep -rln "UserDefaults\|Keychain\|HealthKit\|StoreKit\|AVAudio\|UNUserNotificationCenter\|FoundationModels" FocusOnYourself/Services/ --include="*.swift"` → empty.

### Stores — device-framework IO

Stores are the non-network peer of Services. Same rules: thin, one external system, no business logic, no state beyond constants, no knowledge of key meanings. Registered under `// MARK: - Stores`.

**Existing:** `KeychainStore` (SwiftSecurity, account namespace `"FocusOnYourself"`) · `UserDefaultsStore` (App Group, typed by `UserDefaultsKey`).

**Extraction rule** — same as Use Cases: extract to a Store when a 2nd consumer (Use Case or VM) needs the same primitive. Until then, the framework is inlined in its sole consumer:

| Framework | Status |
|-----------|--------|
| Keychain | Store (AuthUseCase + URLSessionNetworkClient) |
| UserDefaults | Store (5 consumers) |
| HealthKit | inlined in HomeViewModel |
| AVAudio | inlined in MeditationPlayerViewModel |
| StoreKit | inlined in PurchaseUseCase |
| UNUserNotificationCenter | inlined in NotificationsUseCase |
| FoundationModels | inlined in HomeViewModel |

**Callers:** Use Cases (preferred), ViewModels (for single-VM keys, same rule as Services), `NetworkClient` (auth header).

**Invariants:** `grep -rn "Keychain.default" FocusOnYourself --include="*.swift" | grep -v "Stores/Keychain/"` and `grep -rn "UserDefaults(suiteName:" FocusOnYourself --include="*.swift" | grep -v "Stores/UserDefaults/"` → empty.

### Models — placement, one-per-file, and mappers

**Folder split:**
- `Domain/Models/` — business language: `CheckIn`, `Mood`, `UserProfile`, `AffirmationCategory`, `ProductID`, `UserDefaultsKey`, etc.
- `Networking/Models/` — wire-format only: `<Action>Body`, `<Action>Response` / `Backend<Domain>`, shared `EmptyResponse`, etc.

**One top-level type per file**, file named after the type. No grouping conceptually-related types (e.g. `MeditationStep` ≠ `MeditationSession.swift`).

**Exception:** when a backend model needs `toBackendModel()` / `toDomainModel()` mappers, BOTH extensions live in the **backend type's file** (the only case where a model file contains > 1 top-level decl).

**Mapper rules** — required both ways when wire ≠ domain:
- Names: ALWAYS `toBackendModel()` (non-optional) and `toDomainModel()` (optional when any field can fail validation; call sites use `compactMap`).
- Both extensions in the backend file (`Networking/Models/<Backend>.swift`).
- Enum conversion: `.rawValue` outbound; guarded `Enum(rawValue:)` inbound.
- Optional sub-model groups: collect via inline closure: `let factors: CheckInFactors? = { guard let a, let b else { return nil }; return CheckInFactors(...) }()`.

Direct-use wire models (`LoginBody`, `RefreshBody`, `AuthResponse`, `EmptyResponse`) need no mapper.

### Use Cases — shared logic only

- Create one ONLY when 2+ ViewModels need the same operation. Single-VM logic stays in the VM.
- One Use Case per feature domain; group related operations (`CheckInUseCase` does record/streak/merge/queries).
- `@Observable @MainActor final class` when holding reactive state (`ProfileUseCase`, `PurchaseUseCase`). Otherwise plain `final class @MainActor`.
- May inject Services, Stores, hold Calculators (`private let`), inline single-consumer device frameworks, and inject other Use Cases when **delegating** (see below).

**Tell, Don't Ask** — when a Use Case needs work involving another feature's data or services, inject that feature's Use Case and call a method on it. NEVER read its state out and operate on it locally.

❌ `AuthUseCase` reads `profileUseCase.profile.checkIns` then calls `checkinsService.importAll(...)` — feature envy.
✅ `AuthUseCase` calls `checkInUseCase.uploadAllToServer()` / `downloadAndReplaceFromServer()` — owner decides how.

Smell: `someUseCase.someData` read followed by `otherService.someMethod` call → add a method to `someUseCase` and delegate.

**VM → Use Case extraction trigger:** ViewModel B now needs logic that exists in ViewModel A. Create the Use Case (or fold into existing). No preemptive extraction.

### Calculators — pure SOLID logic

Pure `struct`s, held by Use Cases / VMs as `private let calc = XCalculator()`. Given inputs, return outputs.

**Extract when ALL true:** pure (no IO/state/side effects), worth a name (≥ 10 LOC OR ≥ 2 test-worthy edges OR shared by 2+ consumers), reusable in concept. Otherwise inline as `private func`.

**Naming:** every file in `Domain/Calculators/` ends with `Calculator` suffix. No `…Checker/Helper/Validator/Parser`.

**One responsibility — the "and" test:** if the name needs "X and Y", split it. Methods within a Calculator MUST share an input domain OR contribute to the same output kind.

**Splitting a big method (> ~25 LOC):**
1. Read the body as English sentences → each sentence = one responsibility.
2. Extract each as a named `private func` (verbs: `entriesWithFactors(_:)`, `correlate(_:factor:moods:)`).
3. Promote a private helper to its own Calculator only if reused elsewhere.
4. Hard limit 75 LOC (SwiftLint); soft target ≤ 25 LOC per public method.

**Forbidden:** `@Injected`, `@Observable`, `@MainActor`, `import SwiftUI`/`Charts`, mutating instance state, `print`/IO, holding refs to Services/Stores/Use Cases/other Calculators.

**Allowed:** `Int.random` etc. when randomness is part of the algorithmic contract.

### ViewModels

- `@Observable @MainActor final class`. Never `ObservableObject`/`@Published`.
- May inject Use Cases AND Services directly (for single-VM ops). May inline device frameworks until a 2nd VM needs them.
- `Container.shared.resolve(...)` is forbidden in any layer.

**Canonical member order** — every VM follows this layout. `AccountViewModel` is the reference:

```swift
@Observable @MainActor
final class FooViewModel {
    // 1. @ObservationIgnored dependencies and non-observable storage
    @ObservationIgnored @Injected(\.barUseCase) private var barUseCase
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    private let calculator = FooCalculator()

    // MARK: - State
    // 2. Observable stored properties (the @Observable surface)
    var input = ""
    var error: ErrorInfo?

    // MARK: - Computed
    // 3. Computed properties (re-exposures, derived values)
    var isPro: Bool { purchaseUseCase.isPro }

    // 4. init (if any)

    // MARK: - Public methods
    // 5. Public async/sync methods

    // MARK: - Private methods
    // 6. Private helpers (only when present)
}
```

Function NEVER between properties of the same kind. Use the exact MARK strings above (`// MARK: - State`, `// MARK: - Computed`, `// MARK: - Public methods`, `// MARK: - Private methods`) so all VMs read the same way. Tiny VMs (one stored var, no computed) may omit MARKs. Nested types follow the global rule — declared last (see [Member ordering](#member-ordering-classstruct)) even when used by a stored property at the top.

### Forbidden patterns

- Business logic in a Service · device frameworks in `Services/` · single-VM Use Case · `Container.shared.resolve(...)` · a non-state-store Use Case injecting another Use Case (besides delegation to a state-store).
- No Repository layer — removed (see OpenSpec `vm-single-layer-use-cases`). Don't create `Domain/Repositories/` or `Data/`.
- Never `NotificationCenter` for cross-layer state — use `@Observable` or async sequences.

### Dependency Injection (Factory)

All Services / Use Cases / Stores are singletons registered by **protocol type** in `App/Container+App.swift`, grouped by `// MARK: - Services` / `// MARK: - Stores` / `// MARK: - Use Cases`:

```swift
var affirmationService: Factory<AffirmationServiceProtocol> {
    self { @MainActor in AffirmationService() }.singleton
}
var profileUseCase: Factory<ProfileUseCaseProtocol> {
    self { @MainActor in ProfileUseCase() }.singleton
}
```

Inside `@Observable` classes, ALWAYS pair `@ObservationIgnored` with `@Injected` (avoids backing-storage name collision). When mutating tracked properties from inside the class, assign to `self.property` — never `_property` (bypasses observation).

```swift
@Observable @MainActor final class HomeViewModel {
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.affirmationService) private var affirmationService
    private let healthStore = HKHealthStore()
}
```

### Data persistence

No CoreData, no Firebase. All data is JSON-encoded `Codable` in:
- `NSUbiquitousKeyValueStore` (iCloud KVS) — cross-device sync
- App Group UserDefaults (`group.app.ddworks.FocusOnYourself`) — shared with widgets

Keys in `UserDefaultsKey` enum at `Domain/Models/UserDefaultsKey.swift`; access via `UserDefaultsStore`. Root model is `UserProfile` (contains `[CheckIn]`); `ProfileUseCase` is the `@Observable` state store — loads on init, persists on `updateProfile`, calls `WidgetCenter.shared.reloadAllTimelines()`.

### State propagation

`ProfileUseCase` and `PurchaseUseCase` are the `@Observable` state stores. Flow: View → VM computed property → Use Case property. Use Cases re-exposing another Use Case's reactive state must use a **computed property** (`var isPro: Bool { purchaseUseCase.isPro }`) — never cache, or reactivity breaks.

### Navigation

- Root `ContentView` switches `OnboardingFlow` vs `MainTabView` from `AppRootViewModel.onboardingCompleted`.
- `MainTabView` 4 tabs from `AppTab`: `.checkin`, `.meditate`, `.historyInsights`, `.settings`.
- Always `NavigationStack` + typed route enums per feature (`FeatureRoute.swift`). Never `NavigationView`.

### Widgets

`MoodWidget` + `StreakWidget` in `FocusOnYourselfWidgets` read App Group data. Widgets do NOT import main-target files — `WidgetDataProvider.swift` holds mirror copies (`WidgetPendingCheckIn`, etc.). When modifying `CheckIn`/`Mood`/`UserProfile`/`PendingWidgetCheckIn`, update the mirror field-for-field (same names, types, order) — both sides decode the same UserDefaults bytes.

## SwiftUI conventions

### Code is the single source of truth

Swift code is authoritative. Design files (Pencil, Figma) are generated outputs. Code wins on disagreement; tokens are defined in Swift first; never block a code change on a design file.

### Apply `swiftui-pro` rules

- Modern API: `overlay { }` not `overlay(_:)` · `foregroundStyle` not `foregroundColor` · `.clipShape(.rect(cornerRadius:))` not `cornerRadius()`.
- A11y: VoiceOver labels on icon-only buttons; `accessibilityHidden(true)` on decorative images.
- Always pass `value:` to `.animation(...)`.

### Design tokens — always

| What | Token | Never |
|------|-------|-------|
| Colors | `Color.foy*` | `.blue`, `Color(hex:)`, `UIColor` literals |
| Spacing | `Spacing.xs/sm/md/lg/xl/xxl` (xxxs=4 → xxl=32) | raw `8`, `16`, `24` |
| Corner radius | `CornerRadius.*` | `10`, `12`, `.cornerRadius(8)` |
| Typography | `.font(.foy*)`, `.foy*Style()` | `.font(.system(size: 40))` |

Use everywhere padding/spacing appears: `.padding(Spacing.md)`, `VStack(spacing: Spacing.sm)`, `HStack(spacing: Spacing.xs)`, `Spacer(minLength: Spacing.md)`. Corners: `.clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))`.

**Exceptions:** `.frame(width:height:)` / `.frame(maxWidth:)` don't use tokens. One-off values → `private let` at top of struct, never inline. Missing token? Add it to `DS+Spacing.swift` / `DS+CornerRadius.swift`.

Always `.scrollIndicators(.hidden)` on every `ScrollView`. Never the deprecated `showsIndicators: false` initializer parameter.

Full token sets live in `DesignSystem/DS+Colors.swift`, `DS+Typography.swift`, `DS+Spacing.swift`, `DS+CornerRadius.swift` — grep there for the canonical names.

### Screen structure — canonical

```swift
struct ExampleScreen: View {
    @State private var viewModel = ExampleViewModel()
    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ScreenHeaderView(title: "Title")
                ScrollView {
                    VStack(spacing: Spacing.lg) { /* sections */ }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
```

**8 rules every screen satisfies:**
1. Outer: `ZStack { Color.foyBackground.ignoresSafeArea() }`
2. `ScreenHeaderView(title:)` — if header-less, comment `// Screen has no header: <reason>`
3. `Spacing.screenHorizontal` applied once on scroll content `VStack` (never `Spacing.xl`, never raw)
4. `.padding(.bottom, Spacing.screenBottom)` on scroll content `VStack`
5. `VStack(spacing: Spacing.lg)` between sections
6. `.scrollIndicators(.hidden)`
7. No raw spacing/corner values — use tokens; if missing, add to `DS+Spacing.swift`/`DS+CornerRadius.swift`
8. Components inside padded scroll context don't add their own `.padding(.horizontal, ...)`. **Exception:** `.padding(.horizontal, -Spacing.screenHorizontal)` to break out for edge-to-edge content.

**Padding hierarchy:** `Spacing.lg` sections · `Spacing.md` list items + inside cards · `Spacing.sm` icon+text · `Spacing.xs` chips/badges.

### Screens (MVVM)

`Screen` suffix; contains only the VM declaration:

```swift
struct BlockSetupScreen: View {
    @State private var viewModel = BlockSetupViewModel()
    var body: some View { ... }
}
```

ALL state (navigation flags, sheet triggers, selected-item optionals) lives in the VM. Bind via `Bindable(viewModel).property` — no property wrapper change needed:

```swift
.sheet(item: Bindable(viewModel).selectedArticle) { ArticleDetailView(article: $0) }
```

**View conditions:** one VM property inline OK; two+ → computed property on the VM.

### Components

- Feature-scoped → `Features/<F>/Components/`
- App-wide → `DesignSystem/Components/`
- Never inline ad-hoc sub-views in screen files. Never `private var foo: some View` — extract to a named `struct` in `Components/`. Never copy-paste a view body.

### Swift concurrency

Use Cases / Services are `async throws`. VMs call them in `Task {}`:

```swift
func load() {
    Task {
        do { data = try await useCase.fetch() }
        catch { self.error = ErrorInfo(title: "Failed", description: error.localizedDescription) }
    }
}
```

- Never completion handlers in new code · never `try?` to suppress (catch + surface) · cancel superseded tasks (`private var loadTask: Task<Void, Never>?`, cancel before re-launch).
- **Loading flags wrap network IO only.** Set `isLoading = true` immediately before `await <service/useCase call>`, `false` immediately after (use `defer { isLoading = false }` when there's a throw path). Never introduce `Task.sleep` to gate UI transitions — rely on `@Observable` propagation and `.animation(_:value:)` for visual smoothing.
- **Fire-and-forget exception** — silent `Task { _ = try? await ... }` only when ALL three hold: (1) data already persisted locally, (2) failure has no user-visible consequence, (3) a comment explains why.

### Error handling

```swift
enum MyError: Error {
    case caseA, caseB(Error)
    var defaultDescription: String { switch self { ... } }
}
```

VMs expose `var error: ErrorInfo?`. Display via `InlineErrorView(error: error)` — never raw `Text` in `Color.foyOrange`.

### Comments

Never write comments. Exceptions: `// MARK: -` dividers; a non-obvious *why* (hidden constraint, workaround for a specific bug, surprising behavior). Never describe what the code does, reference design tools (Pencil/Figma IDs), name callers, or document the current task.

### Swift idioms

- `Date.now` over `Date()`.
- Date-only ISO8601 strings: `.formatted(.iso8601.year().month().day())`, never `ISO8601DateFormatter().string(from:).prefix(10)`.
- Omit `return` in single-expression functions/computed properties. `if`/`switch` as expressions.

### Member ordering (class/struct)

Fixed order — function NEVER between properties of the same kind. Use `// MARK: -` dividers when grouping helps navigation:

1. Stored properties (`@Injected`, `let`, `var` with stored value)
2. Static constants
3. Computed properties
4. `init`
5. Public methods
6. Private methods
7. Nested types
