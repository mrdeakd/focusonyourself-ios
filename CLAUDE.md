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

**MVVM + Factory DI, iOS 17+, SwiftUI only.**

### Layers

| Layer | Location | Rule |
|-------|----------|------|
| Screens | `Features/*/` | Only a `@State private var viewModel = …ViewModel()` — no state, no logic |
| ViewModels | `Features/*/` | `@Observable @MainActor final class` — all state, all logic, calls services via Task |
| Services | `Services/` | Plain `@MainActor` singletons registered in `Container+App.swift` — NOT `@Observable` |
| Models | `Models/` | Plain `Codable` structs/enums, no logic |
| Design System | `DesignSystem/` | Tokens only — `DS+Colors.swift`, `DS+Spacing.swift`, `DS+Typography.swift`, etc. |
| Components | `Features/*/Components/` or `DesignSystem/Components/` | Reusable views in their own files |

### Dependency Injection (Factory)

All services are registered as singletons in `Container+App.swift` using their **protocol type** — never the concrete class. This enforces the protocol boundary so callers can't reach internal implementation details (e.g. `notifyAll()`):

```swift
var profileService: Factory<ProfileServiceProtocol> {
    self { @MainActor in ProfileService() }.singleton
}
```

ViewModels inject via `@ObservationIgnored @Injected`:

```swift
@Observable @MainActor final class HomeViewModel {
    @ObservationIgnored @Injected(\.profileService) private var profileService
}
```

Views **never** call `Container.shared.resolve()`. Services are never accessed as singletons from views.


### Data Persistence

**No CoreData, no Firebase.** All data is JSON-serialized `Codable` structs stored in:
- `NSUbiquitousKeyValueStore` (iCloud KVS) — syncs across devices
- App Group UserDefaults (`group.app.ddworks.FocusOnYourself`) — shared with widgets

`UserDefaultsService` is the single abstraction over both stores. Keys are defined in a `UserDefaultsKey` enum inside that file.

The root model is `UserProfile` (contains `[CheckIn]`). `ProfileService` owns all read/write operations on it.

### State Propagation

`ProfileService` and `PurchaseService` are `@Observable`. ViewModels expose their reactive state as computed properties that read from the service directly (e.g. `var greeting: String { profileService.profile.name }`). SwiftUI's observation system tracks these reads transitively — when a service property changes, any view that accessed it re-renders automatically. No subscription methods, no local copies, no `.task` wiring needed for state observation. Pure request-response services remain plain `final class`.

### Navigation

- Root (`ContentView`) switches between `OnboardingFlow` and `MainTabView` based on `AppRootViewModel.onboardingCompleted` (computed from `ProfileService.profile`).
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
- `Services/ProfileService.swift` — source of truth for user data, streaks, check-ins
- `Services/UserDefaultsService.swift` — all persistence reads/writes
- `Models/UserProfile.swift` + `Models/CheckIn.swift` — core Codable models (domain/persistence)
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
@ObservationIgnored @Injected(\.profileService) private var profileService
```

- Always pair `@ObservationIgnored` with `@Injected`
- Views never call `Container.shared.resolve()`
- All registrations in `App/Container+App.swift`

### Services

Every service has two files: `XxxServiceProtocol.swift` (the interface) and `XxxService.swift` (the implementation). Services are plain `final class` — no `@Observable`, no `@MainActor`, no `@ObservationIgnored`. All dependencies are injected via `@Injected`:

```swift
// XxxServiceProtocol.swift
protocol XxxServiceProtocol {
    func methodName() async throws -> ReturnType
}

// XxxService.swift
import Factory

final class XxxService: XxxServiceProtocol {
    @Injected(\.networkClient) private var networkClient
    @Injected(\.userDefaultsService) private var userDefaultsService

    func methodName() async throws -> ReturnType {
        try await networkClient.get("/api/path")
    }
}
```

**Container registration** (always via protocol type, no init parameters):
```swift
var myService: Factory<MyServiceProtocol> {
    self { MyService() }.singleton
}
```

**Exception — `ProfileService` and `PurchaseService`**: Both are `@Observable final class` registered with their concrete type (`Factory<ProfileService>` / `Factory<PurchaseService>`). `ProfileService` is passed into the SwiftUI view tree via `.environment()`; `PurchaseService` is injected via `@Injected` but observed transitively through ViewModels. Their `@Injected` dependencies must use `@ObservationIgnored` to prevent a backing-storage name collision with the `@Observable` macro. When mutating `@Observable`-tracked properties from inside the class, always assign to `self.property` — never to the synthesized `_property` backing store, which bypasses the observation system.

**Never use `NotificationCenter`** for propagating state changes between services and views — use `@Observable` or async sequences instead.

**Model placement:**
- API request/response models → `Networking/Models/`
- Domain and persistence models → `Models/`
- No `import SwiftUI` in model files. UI-specific properties (colors, tints) go in a `ModelType+UI.swift` extension placed near the views that consume them.

**Model conversion (domain ↔ backend):** When a domain model needs to be serialised for the API (or deserialised from it), add two extensions — both in the backend model file (`Networking/Models/BackendModel.swift`), not split across files:

```swift
extension CheckIn {
    func toBackendModel() -> BackendCheckIn { … }   // outbound: domain → API
}

extension BackendCheckIn {
    func toDomainModel() -> CheckIn? { … }          // inbound: API → domain (optional = validation can fail)
}
```

Rules:
- Naming: always `toBackendModel()` and `toDomainModel()`.
- `toDomainModel()` returns an optional when any field requires validation (e.g. `guard let mood = Mood(rawValue: mood)`). Use `compactMap` at call sites to filter invalid entries.
- Enum conversion: `.rawValue` outbound; guarded `Enum(rawValue:)` inbound.
- Optional sub-model groups: collect multiple optional fields into an optional struct using an inline closure:
  ```swift
  let factors: CheckInFactors? = {
      guard let sleepQuality, let stressLevel,
            let exercised, let socialQuality else { return nil }
      return CheckInFactors(…)
  }()
  ```

**Views must never access services directly.** No `@Injected` or `Container.shared` in a view struct. All service interaction goes through a ViewModel. The only exception is `ProfileService` accessed via `@Environment(ProfileService.self)` — that is the established SwiftUI observation pattern for the root routing layer.

### Swift Concurrency

Services are `async throws`. ViewModels call them in `Task {}`:

```swift
func load() {
    Task {
        do { data = try await service.fetch() }
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
