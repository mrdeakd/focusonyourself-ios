# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git

Never add `Co-Authored-By: Claude` or any Claude authorship trailer to commit messages.

## Build & Lint

**Build (iOS Simulator):**
```bash
xcodebuild -project FocusOnYourself.xcodeproj -scheme FocusOnYourself \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20
```

**SwiftLint** runs automatically as an Xcode build phase (`swiftlint --fix` then `swiftlint`). To run manually:
```bash
swiftlint --fix && swiftlint
```

There are no unit tests in this project. There is no Makefile or Fastfile — all build automation uses Xcode directly or the `ios-app-release` skill.

**SwiftLint gotcha — `empty_count`**: The opt-in rule auto-converts `x.count > 0` → `!x.isEmpty`. For named tuples or types without `.isEmpty`, suppress with:
```swift
// swiftlint:disable:next empty_count
.someModifier(x.count > 0 ? a : b)
```

**SwiftLint gotcha — `identifier_name`**: The spacing tokens `xs`, `sm`, `md`, `lg`, `xl`, `ys` are excluded in `.swiftlint.yml` (intentional token and math-variable names). For short local variables like `ds` or `ci`, use the full name (`dateString`, `checkIn`).

**SwiftLint gotcha — `closure_body_length`**: SwiftUI `var body` closures can legitimately grow long when views are deeply composed. Suppress individual overruns with `// swiftlint:disable:next closure_body_length` only after confirming sub-view extraction would harm readability. The configured threshold is 100 lines warning / 150 lines error.

**SwiftLint gotcha — Charts `BarMark.cornerRadius()`**: This is the Swift Charts modifier, not the deprecated `View.cornerRadius()`. Do not replace it with `.clipShape`; suppress with `// swiftlint:disable:next legacy_constructor` only if SwiftLint flags it.

Key limits: line length 130 (error), file length 400/500, function body 75 lines, closure body 100/150 lines.

## Architecture

**MVVM + Use Cases + Calculators + Factory DI, iOS 17+, SwiftUI only.**

### Layers

| Layer | Location | Rule | May depend on |
|-------|----------|------|---------------|
| Screen | `Features/<Feature>/<Name>Screen.swift` | Only `@State private var viewModel = …ViewModel()` — no state, no logic | ViewModel |
| ViewModel | `Features/<Feature>/<Name>ViewModel.swift` | `@Observable @MainActor final class` — all VM state + logic. Single-VM logic lives here. Inlines device-framework code when only this VM uses that framework. | Use Cases + Services + Calculators |
| Use Case | `Domain/UseCases/<Feature>/<Name>UseCase.swift` + protocol | **SHARED business logic** across 2+ ViewModels. May be `@Observable` if it holds reactive state (`ProfileUseCase`, `PurchaseUseCase`). Inlines device frameworks (Keychain, UserDefaults, UNUserNotificationCenter, StoreKit) that aren't network. | Services + Calculators + other state-store Use Cases (`ProfileUseCase`) |
| Calculator | `Domain/Calculators/<Name>Calculator.swift` | Pure `struct`. No DI, no `@Observable`, no `@MainActor`, no `import SwiftUI`. All inputs are method args. | Nothing |
| Service | `Services/<Domain>/<Name>Service.swift` + protocol | **NETWORK IO ONLY.** Thin: takes prepared parameters from caller, returns raw decoded data. No caching, no branching, no business logic. No device frameworks (Keychain/UserDefaults/HealthKit/etc.). | `NetworkClient` |
| Domain Model | `Domain/Models/<Name>.swift` | Plain `Codable` struct/enum — one type per file, no logic | Nothing |
| Wire Model | `Networking/Models/<Name>.swift` | Wire-format `Codable` types (request bodies, responses, backend variants) — one type per file. Mapper extensions co-locate with the backend type. | Domain models |
| Design System | `DesignSystem/` | Tokens — `DS+Colors.swift`, `DS+Spacing.swift`, etc. | Nothing |
| Components | `Features/<Feature>/Components/` or `DesignSystem/Components/` | Reusable views in their own files | DesignSystem tokens, parent ViewModel |

### Services — network only

- A Service file may contain ONLY network calls via `networkClient`. No `UserDefaults`, `Keychain`, `HealthKit`, `StoreKit`, `AVAudio`, `UNUserNotificationCenter`, `FoundationModels`.
- A Service does not branch between paths, cache anything, decide when to call, validate inputs, or hold state.
- A Service may encode typed inputs into URL/query/body (transformation for the wire) and decode the response, INCLUDING `.toBackendModel()` / `.toDomainModel()` mappings on Codable models.
- The Service receives prepared parameters from its caller (Use Case or ViewModel) and returns the mapped models (domain types where applicable, or raw decoded backend types where translation isn't needed).
- Services are registered as `Factory<<Name>ServiceProtocol>` in `Container+App.swift` under `// MARK: - Services`.

#### Mandatory method template (ENFORCE on every Service method)

Every Service method **must** follow this exact 4-line structure:

```
1. let path = "..."                                         // endpoint path (base, without query)
2. let <param> = ... / let body = ...                       // params: encode inputs to wire format (zero or more lines)
3. let response: <T> = try await networkClient.get/post(...)  // the call (may interpolate path + params)
4. return response  /  return response.map { ... }          // return, with optional mapping
```

Rules:
- Line 1 is ALWAYS `let path = "..."` — a string literal for the endpoint base, no query string here.
- Lines 2…N are ALWAYS `let <name> = <encoded value>` — one `let` per param transformation (`categories.map(\.rawValue).joined(...)`, `Date.now.formatted(...)`, `.toBackendModel()`, etc.). Skip if there are no params.
- The call line ALWAYS captures into `let response: T = try await networkClient.<verb>(...)`. The query string is built inline at the call site by interpolating the `path` and param `let`s (e.g. `"\(path)?date=\(date)"`).
- The return line is either `return response` or `return response.compactMap { ... }` / `return response.map { ... }` when a domain translation is needed (typically `.toDomainModel()`).
- For void-returning calls (POST with empty response), replace lines 3–4 with `let _: EmptyResponse = try await networkClient.post(path, body: body)` (no return statement). The discard goes on the same call line.
- One method = one network call. If a feature needs multiple round-trips, expose multiple methods on the Service (the caller composes them).

**Conforming examples:**

```swift
// GET with query params
func fetchAffirmations(count: Int, for categories: [AffirmationCategory]) async throws -> [CachedAffirmation] {
    let path = "/api/affirmations/batch"
    let categoryParams = categories.map(\.rawValue).joined(separator: ",")
    let response: [CachedAffirmation] = try await networkClient.get(
        "\(path)?categories=\(categoryParams)&count=\(count)"
    )
    return response
}

// GET with mapping
func fetch() async throws -> [CheckIn] {
    let path = "/api/checkins"
    let response: [BackendCheckIn] = try await networkClient.get(path)
    return response.compactMap { $0.toDomainModel() }
}

// POST with body, typed response
func login(email: String, password: String) async throws -> AuthResponse {
    let path = "/api/auth/login"
    let body = LoginBody(email: email, password: password)
    let response: AuthResponse = try await networkClient.post(path, body: body)
    return response
}

// POST with body, no response
func post(_ checkIn: CheckIn) async throws {
    let path = "/api/checkins"
    let body = checkIn.toBackendModel()
    let _: EmptyResponse = try await networkClient.post(path, body: body)
}

// GET no params
func allSessions() async throws -> [MeditationSession] {
    let path = "/api/meditations"
    let response: [MeditationSession] = try await networkClient.get(path)
    return response
}
```

**Forbidden in Service methods (violations of the template):**
- `guard !x.isEmpty else { return [] }` — validation belongs to the caller
- `if/else` branching between alternate paths — split into two methods instead (`allSessions()` + `sessions(in:)`)
- Inline `Date.now` or other runtime decisions that aren't pure encoding — the caller provides the value when it's a business decision
- Caching, retry loops, fallback logic — those belong in the Use Case or ViewModel

**Invariant** (run to verify): `grep -rln "UserDefaults\|Keychain\|HealthKit\|StoreKit\|AVAudio\|UNUserNotificationCenter\|FoundationModels" FocusOnYourself/Services/ --include="*.swift"` — must return empty.

### Models — placement, one-per-file, and domain mappers

**Folder split:**
- `Domain/Models/` — domain types (the language of the business): `CheckIn`, `CheckInFactors`, `Mood`, `UserProfile`, `AffirmationCategory`, `MeditationCategory`, `ArticleTopic`, `PendingWidgetCheckIn`, `ProductID`, `PurchaseError`, `PurchaseOutcome`, `UserDefaultsKey`, etc.
- `Networking/Models/` — wire-format ONLY (request bodies, response payloads, backend variants, shared envelopes): `AuthResponse`, `LoginBody`, `RefreshBody`, `BackendCheckIn`, `ImportCheckInsBody`, `Article`, `MeditationSession`, `MeditationStep`, `CachedAffirmation`, `EmptyResponse`, etc.

**One struct/enum per file.** Every top-level type lives in its own file named after the type (`<TypeName>.swift`). No grouping multiple types in one file even when they're conceptually related (e.g. `MeditationStep` does NOT live in `MeditationSession.swift`; `ImportCheckInsBody` does NOT live in `BackendCheckIn.swift`).

**Exception — mapper extensions co-locate with the backend type.** When a backend model needs `toBackendModel()` / `toDomainModel()` mappers, BOTH extensions live in the **backend type's file** (e.g. `Networking/Models/BackendCheckIn.swift` contains the `BackendCheckIn` struct, the `extension CheckIn { toBackendModel() }`, and the `extension BackendCheckIn { toDomainModel() }`). This is the only case where a model file contains more than one top-level declaration.

**Naming conventions in `Networking/Models/`:**
- Request body: `<Action>Body` (e.g. `LoginBody`, `RefreshBody`, `ImportCheckInsBody`)
- Response payload: `<Action>Response` (e.g. `AuthResponse`, `RefreshResponse`) OR `Backend<DomainType>` when the response is a backend-shaped variant of a domain type (e.g. `BackendCheckIn`)
- Empty/discard response: shared `EmptyResponse`

**Domain mappers — REQUIRED both ways when the wire shape differs from the domain shape.** If a backend model has even one field that needs validation, renaming, enum conversion, or restructuring before it becomes a domain model, BOTH mappers must exist in the backend model file:

```swift
// Networking/Models/BackendCheckIn.swift

struct BackendCheckIn: Codable {
    let date: String
    let mood: String
    let feelingsDescription: String?
    let factors: BackendCheckInFactors?
}

extension CheckIn {
    func toBackendModel() -> BackendCheckIn { … }   // outbound: domain → API
}

extension BackendCheckIn {
    func toDomainModel() -> CheckIn? { … }          // inbound: API → domain
}
```

**Mapper rules:**
- Naming: ALWAYS `toBackendModel()` and `toDomainModel()`. No other names.
- Both extensions live in the **backend model file** (`Networking/Models/<Backend>.swift`), never split across files.
- `toDomainModel()` returns an **optional** when any field can fail validation (e.g. `guard let mood = Mood(rawValue: rawMood)`). Call sites use `compactMap { $0.toDomainModel() }` to filter invalid entries.
- `toBackendModel()` returns non-optional — the domain model is already valid by construction.
- Enum conversion: `.rawValue` outbound; guarded `Enum(rawValue:)` inbound.
- Optional sub-model groups: collect multiple optional fields into an optional struct using an inline closure:
  ```swift
  let factors: CheckInFactors? = {
      guard let sleepQuality, let stressLevel,
            let exercised, let socialQuality else { return nil }
      return CheckInFactors(…)
  }()
  ```

**When mappers are NOT required**: if a backend model is used directly without translation (the wire shape matches the consumer's needs exactly), no mapper is needed. Examples: `LoginBody`, `RefreshBody`, `AuthResponse`, `EmptyResponse` — they're used as-is. But the moment a domain type needs a different shape from the wire, both mappers MUST exist together.

**Invariant** (run to verify): `ls FocusOnYourself/Models/ | xargs -I{} grep -l "Codable" FocusOnYourself/Models/{}` — files listed here that are network request/response shapes belong in `Networking/Models/` instead. Domain models in `Models/` may still be `Codable` (for UserDefaults persistence), but they aren't network wire formats.

### Use Cases — only when SHARED across 2+ ViewModels

- Create a Use Case when (and only when) two or more ViewModels need the same operation. Single-VM logic stays in the ViewModel.
- One Use Case per feature domain; group related operations together (`CheckInUseCase` covers `record`, `streakStats`, `mergeWidgetCheckIn`, query properties).
- A Use Case may be `@Observable` when it holds reactive state (`ProfileUseCase` holds `UserProfile`, `PurchaseUseCase` holds `isPro`). Otherwise it's plain `final class @MainActor`.
- A Use Case may inject Services (network), may hold Calculators as `private let`, and may inline non-network device frameworks (Keychain, UserDefaults via AppGroup, UNUserNotificationCenter, StoreKit) — services are network-only, so any device framework lives here or in a VM.
- A Use Case does NOT inject other Use Cases EXCEPT the `@Observable` state-store ones (`ProfileUseCase`, `PurchaseUseCase`) which are explicitly shared state.

**When to extract from VM → Use Case**:
- ViewModel A has logic X. ViewModel B now also needs X.
- Create `XUseCase` (or fold into an existing relevant Use Case). Move the logic. Both VMs inject the Use Case.
- This is the only trigger — don't extract preemptively.

### Calculators — pure, > ~10 LOC

- Pure `struct`. All inputs are method arguments, all outputs are return values.
- No DI, no `@Observable`, no `@MainActor`, no `import SwiftUI` (other framework imports like `HealthKit` are allowed for type mapping).
- Use Calculators when a chunk of pure logic gets large enough to benefit from isolation (distribution algorithms, statistical math, mapping rules, date math).

### ViewModels — inject Use Cases and/or Services

- `@Observable @MainActor final class`.
- May inject Use Cases for shared logic, and Services directly for single-VM operations.
- May inline device-framework code (HealthKit, AVAudio, FoundationModels) when only this VM uses that framework. Pull it into a Use Case as soon as a 2nd VM needs the framework.
- `Container.shared.resolve(...)` is forbidden.

### When adding a new feature

1. If it touches a new network endpoint → add a Service (and protocol) under `Services/<Domain>/`. Network only.
2. If it has pure logic ≥ ~10 lines (math, transforms, validation) → add a Calculator under `Domain/Calculators/`.
3. Implement the feature in the ViewModel using the Service / Calculator directly. Inline device frameworks inside the VM if needed.
4. If/when a second ViewModel needs the same logic, extract it to a Use Case under `Domain/UseCases/<Feature>/` and register it in `App/Container+App.swift`.
5. Never put business logic in a Service. Never duplicate logic across VMs — extract on second use.

### Forbidden patterns

- Business logic in a Service (caching dates, branching on flags, transformation rules).
- Device-framework code in `Services/` (Keychain, UserDefaults, HealthKit, StoreKit, AVAudio, UNUserNotificationCenter, FoundationModels). These live in Use Cases or ViewModels.
- A Use Case used by only one ViewModel (dissolve into that VM until a 2nd consumer appears).
- `Container.shared.resolve(...)` in any layer.
- A Use Case injecting another non-state-store Use Case.

### There is NO Repository layer

The Repository pattern was removed (see OpenSpec change `vm-single-layer-use-cases`). Operations that previously sat in a `*RepositoryImpl` are inlined into the corresponding Use Case. Do not introduce new files under `Domain/Repositories/` or `Data/`.

### Dependency Injection (Factory)

All Services and Use Cases are registered as singletons in `App/Container+App.swift` using their **protocol type** — never the concrete class. Registrations are organised into `// MARK: -` sections: Services (network), Use Cases.

```swift
// MARK: - Services (network only)
var affirmationService: Factory<AffirmationServiceProtocol> {
    self { @MainActor in AffirmationService() }.singleton
}

// MARK: - Use Cases
var profileUseCase: Factory<ProfileUseCaseProtocol> {
    self { @MainActor in ProfileUseCase() }.singleton
}
```

ViewModels inject Use Cases AND, when appropriate, Services directly:

```swift
@Observable @MainActor final class HomeViewModel {
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase     // shared
    @ObservationIgnored @Injected(\.checkInUseCase) private var checkInUseCase     // shared
    @ObservationIgnored @Injected(\.affirmationService) private var affirmationService // single-VM
    private let healthStore = HKHealthStore()                                        // inlined framework
}
```

Use Cases inject Services and hold Calculators as `private let`. State-store Use Cases (`ProfileUseCase`, `PurchaseUseCase`) are `@Observable`:

```swift
@Observable @MainActor
final class ProfileUseCase: ProfileUseCaseProtocol {
    private(set) var profile = UserProfile()
    private let defaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
}
```

Views never call `Container.shared.resolve()`.

### Data Persistence

**No CoreData, no Firebase.** All data is JSON-serialized `Codable` structs stored in:
- `NSUbiquitousKeyValueStore` (iCloud KVS) — syncs across devices
- App Group UserDefaults (`group.app.ddworks.FocusOnYourself`) — shared with widgets

Keys are defined in the `UserDefaultsKey` enum at `Models/UserDefaultsKey.swift`. There is no `UserDefaultsService` — each Use Case (or ViewModel, for single-VM data) instantiates `UserDefaults(suiteName: AppGroup.suiteName)` inline.

The root model is `UserProfile` (contains `[CheckIn]`). `ProfileUseCase` is the `@Observable` state store: it loads `UserProfile` on init, persists on every `updateProfile`, and triggers `WidgetCenter.shared.reloadAllTimelines()`. All profile reads / writes go through `ProfileUseCase`.

### State Propagation

`ProfileUseCase` and `PurchaseUseCase` are the `@Observable` state stores. Reactive reads flow: View body → ViewModel computed property → Use Case property. SwiftUI's observation system tracks the underlying `@Observable` access transitively, so the View re-renders automatically when the state changes. Use Cases that expose reactive state from another `@Observable` Use Case must expose it as a **computed property** (e.g. `var isPro: Bool { purchaseUseCase.isPro }`) — never cache the value, or the reactivity breaks.

### Navigation

- Root (`ContentView`) switches between `OnboardingFlow` and `MainTabView` based on `AppRootViewModel.onboardingCompleted` (computed from `ProfileUseCase.profile`).
- `MainTabView` has 4 tabs driven by `AppTab` enum: Check-In, Meditate, History/Insights, Settings. (enum cases: `.checkin`, `.meditate`, `.historyInsights`, `.settings`)
- Use `NavigationStack` with typed route enums per feature. Never use `NavigationView`.

### Widgets

Two widgets (`MoodWidget`, `StreakWidget`) in the `FocusOnYourselfWidgets` target read data from the shared App Group. They do **not** import any main-target files — widget-specific model copies live in `WidgetDataProvider.swift`. Keep widget models in sync with main-app models manually when changing `CheckIn`, `Mood`, or `UserProfile`.

## Design System Tokens

Always use tokens — never raw numbers or colors inline.

| What | Token source |
|------|-------------|
| Colors | `Color.foyNavy`, `Color.foyBackground`, `Color.foyCard`, `Color.foyOrange`, etc. |
| Spacing | `Spacing.xs/sm/md/lg/xl/xxl` (xxxs=4 → xxl=32) |
| Corner radius | `CornerRadius.*` |
| Typography | `.font(.foyBody)`, `.foyBodyStyle()`, etc. |

For one-off sizes with no matching token, extract to a `private let` at the top of the struct.

Always add `.scrollIndicators(.hidden)` to every `ScrollView`.

## Key Files

- `App/Container+App.swift` — all service registrations; add new services here
- `Domain/UseCases/Profile/ProfileUseCase.swift` — `@Observable` state store for `UserProfile`; owns load/persist + widget reload
- `Domain/UseCases/CheckIn/CheckInUseCase.swift` — check-in CRUD + streak via `StreakCalculator`
- `Domain/UseCases/Auth/AuthUseCase.swift` — login/register/refresh + post-auth sync; inlines Keychain
- `Domain/UseCases/Purchase/PurchaseUseCase.swift` — `@Observable` `isPro` + StoreKit
- `Models/UserDefaultsKey.swift` — App Group UserDefaults key enum
- `Domain/Models/UserProfile.swift` + `Domain/Models/CheckIn.swift` — core domain models
- `Networking/Models/Article.swift` + `Networking/Models/MeditationSession.swift` — API response models
- `DesignSystem/DS+Colors.swift` — full color token list
- `DesignSystem/DS+Spacing.swift` — spacing scale
- `FocusOnYourselfWidgets/WidgetDataProvider.swift` — widget data layer (keep in sync with main models)

## Swift/SwiftUI Conventions

### Code is the Single Source of Truth

Swift code is always authoritative. Design files (Pencil, Figma) are generated outputs — never the source of requirements.
- When code and a design file disagree, code wins.
- Design tokens are defined in Swift first, then synced to design tools.
- Never hold up a code change because a design file hasn't been updated.

When writing or reviewing any SwiftUI view, also apply **`swiftui-pro`** rules:
- Deprecated API: `overlay(_:)` → `overlay { }`, `foregroundColor` → `foregroundStyle`, `cornerRadius()` → `clipShape(.rect(cornerRadius:))`
- Accessibility: VoiceOver labels on icon-only buttons, `accessibilityHidden(true)` on decorative images
- Always supply a `value:` to `.animation()`

### Design System Tokens

Always use tokens — never raw values:

| What | Use | Never use |
|------|-----|-----------|
| Colors | `Color.foyBackground`, `Color.foyNavy`, `Color.foyForeground`, etc. | `.blue`, `Color(hex:)`, `UIColor` literals |
| Spacing | `Spacing.xs/sm/md/lg/xl/xxl` | `8`, `16`, `24` as magic numbers |
| Corner radius | `CornerRadius.*` | `10`, `12`, `.cornerRadius(8)` |
| Typography | `.font(.foyNavTitle)`, `.font(.foyBody)`, etc. | `.font(.system(size: 40))` |

`Spacing.*` everywhere padding or spacing appears: `.padding(Spacing.md)`, `VStack(spacing: Spacing.sm)`, `HStack(spacing: Spacing.xs)`, `Spacer(minLength: Spacing.md)`.

`CornerRadius.*` for all corner radii: `.clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))`.

**Exception:** `.frame(width:height:)` and `.frame(maxWidth:)` do not use tokens.

**One-off values:** extract to `private let` at top of struct — never inline.

Always `.scrollIndicators(.hidden)` on every `ScrollView`. Never use deprecated `showsIndicators: false` initializer parameter.

**Color tokens:** `foyBackground`, `foyCard`, `foyForeground`, `foyForegroundSecondary`, `foyPlaceholder`, `foyBorder`, `foyButtonDisabled`, `foyNavy`, `foyNavyTint`, `foyOrange`, `foyOrangeTint`, `foyOrangeAccent`, `foyMoodBackground`, `foyCalendarSkipped`, `foyDetailPencil`, `foyDetailDotFill`, `foyDetailDotStroke`, `foyGreen`, `foyGreenTint`, `foyOnPrimary`, `foyScrim`, `foyUpgradeCardBg`, `foyUpgradeCardBorder`, `foyUpgradeIconBg`, `foyFreeBadgeBg`

**Typography tokens:** `.foyDisplayTitle`, `.foySectionTitle`, `.foyNavTitle`, `.foyHeadline`, `.foyBody`, `.foyBodyMedium`, `.foyBodySemibold`, `.foyButtonLabel`, `.foyInputText`, `.foyQuote`, `.foyCaption`, `.foyCaptionMedium`, `.foyCaptionSemibold`, `.foyStatValue`, `.foyHint`, `.foyHintMedium`, `.foySkipLabel`, `.foySkipLabelMedium`, `.foySectionLabel`, `.foySectionLabelSemibold`, `.foyMicro`, `.foyMicroMedium`, `foyMeditationTimer(size:)`. Style modifiers: `.foyDisplayTitleStyle()`, `.foySectionTitleStyle()`, `.foyBodyStyle()`, `.foySectionLabelStyle()`.

### Screen Structure (canonical template)

```swift
struct ExampleScreen: View {
    @State private var viewModel = ExampleViewModel()

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ScreenHeaderView(title: "Title")
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // sections here
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
```

**8 rules every screen must satisfy:**
1. Outermost layer: `ZStack { Color.foyBackground.ignoresSafeArea() }`
2. Always `ScreenHeaderView(title:)`. If header-less: document it with `// Screen has no header: <reason>`
3. `Spacing.screenHorizontal` applied once on scroll content `VStack`. Never `Spacing.xl`. Never raw numbers.
4. Always `.padding(.bottom, Spacing.screenBottom)` on scroll content `VStack`
5. `VStack(spacing: Spacing.lg)` between major sections
6. Always `.scrollIndicators(.hidden)`
7. No raw spacing/corner values — use tokens; if missing add to `DS+Spacing.swift` or `DS+CornerRadius.swift`
8. Components inside a padded scroll context must not add their own `.padding(.horizontal, ...)` — **Exception:** use `.padding(.horizontal, -Spacing.screenHorizontal)` to intentionally break out of scroll padding for edge-to-edge content (e.g. carousels, full-bleed banners).

**Component padding hierarchy:** `Spacing.lg` between sections · `Spacing.md` between list items · `Spacing.sm` for icon+text · `Spacing.xs` for chips/badges · `Spacing.md` inside cards

### Screen Views (MVVM)

Screens are named with `Screen` suffix and contain **only** the ViewModel declaration:

```swift
struct BlockSetupScreen: View {
    @State private var viewModel = BlockSetupViewModel()  // ✅ @State, not @StateObject
    var body: some View { ... }
}
```

All state (including navigation booleans, selected-item optionals, sheet triggers) belongs in the ViewModel. Bind with `Bindable(viewModel).property` — no property wrapper change required:

```swift
.sheet(item: Bindable(viewModel).selectedArticle) { article in ArticleDetailView(article: article) }
```

**View conditions:** one ViewModel property inline is fine. Two or more → computed property on ViewModel:

```swift
// ✅ ViewModel
var showRetry: Bool { !isLoading && hasError }
// ✅ View
if viewModel.showRetry { RetryButton() }
```

### ViewModels

```swift
@Observable @MainActor
final class MyViewModel {
    var isLoading = false
    var error: ErrorInfo?
    @ObservationIgnored @Injected(\.myService) private var myService
}
```

- `@Observable @MainActor final class` — always. Never `ObservableObject`/`@Published`.
- Screens own with `@State`. Child views with bindings use `@Bindable`. Read-only children use plain `var`.
- Never use `private var foo: some View` computed view properties — extract to named `struct` in `Components/`.

### Reusable Components

- Feature-scoped → `Features/FeatureName/Components/`
- App-wide → `DesignSystem/Components/`
- Never inline ad-hoc sub-views in screen files. Never copy-paste a view body.

### Dependency Injection

```swift
@ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
```

- Always pair `@ObservationIgnored` with `@Injected` inside `@Observable` classes
- Views never call `Container.shared.resolve()`
- All registrations in `App/Container+App.swift` under `// MARK: - Services` and `// MARK: - Use Cases`

### Services (network only)

Every Service has two files: `<Name>ServiceProtocol.swift` and `<Name>Service.swift`. Services are plain `final class` — no `@Observable`, no `@MainActor` necessary (added when required for callers). The Service injects `networkClient` ONLY and does nothing else:

```swift
// ArticlesServiceProtocol.swift
protocol ArticlesServiceProtocol {
    func dailyArticles() async throws -> [Article]
}

// ArticlesService.swift
import Factory
import Foundation

final class ArticlesService: ArticlesServiceProtocol {
    @Injected(\.networkClient) private var networkClient

    func dailyArticles() async throws -> [Article] {
        try await networkClient.get("/api/articles/today")
    }
}
```

**Container registration** (always via protocol type, no init parameters):
```swift
var articlesService: Factory<ArticlesServiceProtocol> {
    self { @MainActor in ArticlesService() }.singleton
}
```

**State-store Use Cases — `ProfileUseCase`, `PurchaseUseCase`**: Both are `@Observable @MainActor final class` registered with their protocol type. They hold reactive state (`UserProfile`, `isPro`) and inline framework code (UserDefaults for persistence, StoreKit for transactions). Their `@Injected` dependencies must use `@ObservationIgnored` to prevent a backing-storage name collision with the `@Observable` macro. When mutating `@Observable`-tracked properties from inside the class, always assign to `self.property` — never to the synthesized `_property` backing store, which bypasses the observation system.

**Never use `NotificationCenter`** for propagating state changes between layers — use `@Observable` or async sequences instead.

**Model placement is governed by the "Networking models" section earlier in this file** — backend models go in `Networking/Models/` with both `toBackendModel()` / `toDomainModel()` mappers when the wire shape differs from the domain; domain models go in `Models/`. No `import SwiftUI` in model files.

**Views must never access services, use cases, or `Container.shared` directly.** All interaction goes through a ViewModel. **ViewModels must never access services directly** — all service interaction goes through a Use Case (see "The one-layer rule for ViewModels" earlier in this file).

### Swift Concurrency

Services and Use Cases are `async throws`. ViewModels call Use Cases in `Task {}`:

```swift
func load() {
    Task {
        do { data = try await useCase.fetch() }
        catch { self.error = ErrorInfo(title: "Failed", description: error.localizedDescription) }
    }
}
```

- Never completion handlers in new code — use `async throws`
- Never `try?` to suppress errors — always catch and surface
- Cancel superseded tasks: store as `private var loadTask: Task<Void, Never>?`, cancel before re-launching

**Best-effort fire-and-forget pattern** (use sparingly): For non-critical background sync where local state is already saved and a network failure has no user-visible consequence, a silent Task is permitted:
```swift
// Local state is already persisted above — network sync is advisory only
Task { [weak self] in
    guard let self else { return }
    _ = try? await networkClient.post(path, body: body) as EmptyResponse
}
```
Only allowed when all three conditions hold: (1) data is already persisted locally, (2) failure has no user-visible consequence, (3) a comment explains why silent failure is acceptable.

### Error Handling

```swift
enum MyError: Error {
    case caseA
    case caseB(Error)
    var defaultDescription: String { switch self { ... } }
}
```

ViewModels expose `var error: ErrorInfo?`. Views display with `InlineErrorView(error: error)` — never raw `Text` with `Color.foyOrange`.

### Navigation

Always `NavigationStack` — never `NavigationView`. Route enums per feature (`FeatureRoute.swift`). Navigation state owned by root screen `@State` or parent ViewModel.

### Comments

Never write comments. The only exceptions are:
- `// MARK: -` section dividers
- A comment that explains a non-obvious *why* — a hidden constraint, a workaround for a specific bug, or behavior that would surprise a reader

Never write comments that describe what the code does, reference design tools (Pencil, Figma node IDs), name callers, or document current tasks.

### Swift Idioms

- Prefer `Date.now` over `Date()` for clarity.
- For date-only ISO8601 strings (e.g. API query params), use `.formatted(.iso8601.year().month().day())` — never `ISO8601DateFormatter().string(from:).prefix(10)`.
- Omit `return` in single-expression functions and computed properties. `if`/`switch` can be used as expressions.

### Widget Model Sync

When modifying `CheckIn`, `Mood`, `UserProfile`, or `PendingWidgetCheckIn`, manually update `FocusOnYourselfWidgets/WidgetDataProvider.swift`. The widget target cannot import the main app, so `WidgetDataProvider.swift` contains mirror copies (`WidgetPendingCheckIn`, etc.) that must be kept field-for-field identical — same property names, same types, same order — because both sides encode/decode the same `UserDefaults` data.
