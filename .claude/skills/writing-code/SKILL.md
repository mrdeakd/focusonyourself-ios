---
name: writing-code
description: >
  ALWAYS load this skill automatically whenever writing, adding, or modifying any code file in this
  project. Enforces Swift/SwiftUI conventions, design system token usage, MVVM screen structure,
  component organization, dependency injection patterns, and error handling rules specific to
  the FocusOnYourself codebase. Do not skip this skill for any code changes.
---

# Writing Code

## SwiftUI Views — Design System Tokens

When writing or modifying any SwiftUI view, **always use the design system constants** instead of raw values:

| What | Use | Never use |
|------|-----|-----------|
| Colors | `Color.foyBackground`, `Color.foyNavy`, `Color.foyForeground`, etc. (`Colors.swift`) | `.blue`, `Color(hex:)`, `UIColor` literals |
| Spacing | `Spacing.xs/sm/md/lg/xl/xxl` (`Spacing.swift`) | `8`, `16`, `24` as magic numbers |
| Corner radius | `CornerRadius.*` (`CornerRadius.swift`) | `10`, `12`, `.cornerRadius(8)` |
| Typography | `.font(.foyNavTitle)`, `.font(.foyBody)`, etc. (`Typography.swift`) | `.font(.system(size: 40))`, `.font(.title)` |

### Spacing tokens — where they apply

`Spacing.*` tokens must be used **everywhere a padding or spacing value appears**:

- `.padding(Spacing.md)`
- `.padding(.horizontal, Spacing.lg)`
- `VStack(spacing: Spacing.sm)`
- `HStack(spacing: Spacing.xs)`
- `LazyVStack(spacing: Spacing.sm)`
- `Spacer(minLength: Spacing.md)`

`CornerRadius.*` tokens must be used for all corner radius values:

- `.cornerRadius(CornerRadius.md)`
- `.clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))`

**Exception — width and height are excluded.** `.frame(width: 44, height: 44)` and `.frame(maxWidth: .infinity)` do not use tokens; no matching token exists for layout dimensions.

**One-off values:** if a truly unique spacing value exists with no matching token, extract it to a `private let` constant at the top of the struct — never leave the raw number inline in the view body.

**Before (wrong — raw magic numbers):**
```swift
VStack(spacing: 12) {           // ❌ raw number
    Text("Hello")
        .padding(.horizontal, 16)  // ❌ raw number
}
.cornerRadius(8)                // ❌ raw number
```

**After (correct — design system tokens):**
```swift
VStack(spacing: Spacing.sm) {              // ✅ token
    Text("Hello")
        .padding(.horizontal, Spacing.md)  // ✅ token
}
.cornerRadius(CornerRadius.sm)             // ✅ token
```

### ScrollView indicators

Always apply `.scrollIndicators(.hidden)` to every `ScrollView`. Never leave the default visible indicator.

### Color tokens

Full token list: `foyBackground`, `foyNavy`, `foyNavyTint`, `foyForeground`, `foyForegroundSecondary`, `foyPlaceholder`, `foyBorder`, `foyButtonDisabled`, `foyCard`, `foyOrange`, `foyOrangeTint`, `foyMoodBackground`, `foyCalendarSkipped`

| What | Correct token |
|------|--------------|
| Background | `Color.foyBackground` |
| Primary/brand | `Color.foyNavy` |
| Primary text | `Color.foyForeground` |
| Secondary text | `Color.foyForegroundSecondary` |
| Card fill | `Color.foyCard` |
| Orange accent | `Color.foyOrange` |
| Border | `Color.foyBorder` |
| Placeholder / disabled text | `Color.foyPlaceholder` |

### Typography tokens

Tokens (use with `.font()`):
- `.foyDisplayTitle` (Inter 32px light)
- `.foySectionTitle` (Inter 28px light)
- `.foyNavTitle` (Inter 18px medium)
- `.foyBody` (Inter 15px regular)
- `.foyButtonLabel` (Inter 16px medium)
- `.foyInputText` (Inter 16px regular)
- `.foyHint` (Inter 12px regular)
- `.foySkipLabel` (Inter 14px regular)
- `.foySectionLabel` (Inter 11px medium)

Style modifiers (add kerning/line-spacing, use instead of `.font()`):
- `.foyDisplayTitleStyle()` — 32px light, kerning −0.5
- `.foySectionTitleStyle()` — 28px light, kerning −0.5
- `.foyBodyStyle()` — 15px, lineSpacing 9pt
- `.foySectionLabelStyle()` — 11px medium, kerning 0.8

## Code Organization

- When adding new modifiers, views, or components to the design system, create a separate file inside the `DesignSystem/` folder (e.g. `DS+Typography.swift`, `DS+Animations.swift`) rather than adding everything to `DS.swift` or `DS+Components.swift`.
- Only write comments where the code is genuinely complex or non-obvious. Self-explanatory code needs no comment.

## Screen Views (MVVM)

A "screen" (a full-screen navigation destination) must be named with a `Screen` suffix (e.g. `BlockSetupScreen`, not `BlockSetupView`) and must contain **only** its ViewModel declaration. All state, logic, and side-effects belong in the ViewModel — no exceptions.

**Before (wrong):**
```swift
struct BlockSetupView: View {      // ❌ wrong suffix
    @State private var isLoading = false          // ❌ state in screen
    @State private var selectedApps: Set<ApplicationToken> = []

    var body: some View {
        Button("Block") {
            isLoading = true
            ScreenTimeService.shared.block(selectedApps) // ❌ logic in view
        }
    }
}
```

**After (correct):**
```swift
struct BlockSetupScreen: View {    // ✅ Screen suffix
    @State private var viewModel = BlockSetupViewModel()  // ✅ @State, not @StateObject

    var body: some View {
        Button("Block") { viewModel.blockSelected() }
    }
}
```

The ViewModel owns all state, calls services, and exposes intent methods. The screen only renders and forwards user actions.

## View Conditions

**One ViewModel property inline is fine.** A view may read a single VM property directly in a condition:

```swift
if viewModel.isLoading { ProgressView() }
```

**Two or more ViewModel properties → computed property on the ViewModel.** When a condition combines two or more VM properties, extract it to a `var` on the ViewModel. The view then reads only that single derived property.

**Before (wrong — compound condition in the view):**
```swift
// ❌ Inline compound condition — can't be unit-tested
if !viewModel.isLoading && viewModel.hasError {
    RetryButton()
}
```

**After (correct — computed property on the ViewModel):**
```swift
// ✅ ViewModel exposes a single testable property
@Observable @MainActor
final class SomeViewModel {
    var isLoading = false
    var hasError = false

    var showRetry: Bool { !isLoading && hasError }
}

// ✅ View reads one property
if viewModel.showRetry {
    RetryButton()
}
```

**Rationale:** Compound conditions in views cannot be unit-tested. Computed properties on the ViewModel can be tested in isolation, keeping view logic minimal and verifiable.

## ViewModels — `@Observable @MainActor`

All ViewModels use the `@Observable` macro AND `@MainActor`. `ObservableObject` and `@Published` must **not** be used in new code. Existing ViewModels using `ObservableObject` must be migrated when touched.

```swift
// ✅ All ViewModels use @Observable @MainActor final class
@Observable @MainActor
final class BlockSetupViewModel {
    var isLoading = false
    var errorMessage: String?
    // No @Published, no ObservableObject conformance needed
}
```

View ownership rules:

```swift
// ✅ @State for root-owned ViewModels (replaces @StateObject)
struct BlockSetupScreen: View {
    @State private var viewModel = BlockSetupViewModel()
}

// ✅ @Bindable for child views that need two-way bindings
struct SomeChildView: View {
    @Bindable var viewModel: BlockSetupViewModel
    // ...
    TextField("Name", text: $viewModel.name)
}

// ✅ plain let/var for read-only child views
struct ReadOnlyChildView: View {
    var viewModel: BlockSetupViewModel
}
```

## Reusable Components

### Reusability check

Whenever you write or touch a view, ask: **"Is this used (or likely to be used) in more than one place?"** If yes, extract it into its own file — never leave it inlined in a screen or another component.

### Placement rule

| Scope | Location |
|-------|----------|
| Used only within one feature | `Features/FeatureName/Components/` |
| Used across multiple features or app-wide | `DesignSystem/Components/` |

### Rules

- Do **not** inline ad-hoc sub-views inside screen files.
- **Never copy-paste a view body into two screens.** Extract once, share everywhere.
- Use `private struct` only for trivial, truly local layout helpers that have no reuse potential and would clutter a separate file.

```
Features/
  BlockSetup/
    BlockSetupScreen.swift
    BlockSetupViewModel.swift
    Components/
      AppRowView.swift          ✅ feature-scoped reusable view → own file
      SectionHeaderView.swift   ✅ feature-scoped reusable view → own file

DesignSystem/
  Components/
    PrimaryButtonView.swift     ✅ app-wide reusable view → DesignSystem/Components/
```

## Dependency Injection

Services are injected into ViewModels using Factory's `@Injected` property wrapper — **not** via `init` parameters or `Container.shared.resolve()`.

**Pattern:**
```swift
@Observable @MainActor
final class BlockSetupViewModel {
    @ObservationIgnored @Injected(\.profileService) private var profileService
    @ObservationIgnored @Injected(\.affirmationService) private var affirmationService
}
```

Rules:
- Always pair `@ObservationIgnored` with `@Injected` — the property wrapper is not observable.
- Views **never** call `Container.shared.resolve()` or access services directly.
- Services are registered as singletons in `App/Container+App.swift` — add new services there.
- Never use `Container.shared.resolve()` in init parameters; the `@Injected` wrapper handles resolution automatically.

**Screens instantiate their ViewModel directly:**
```swift
// ✅ correct — @Injected in ViewModel handles service resolution
@State private var viewModel = DashboardViewModel()
```

## Services

Services are `@Observable @MainActor` singletons registered in `App/Container+App.swift`:

```swift
// In Container+App.swift
extension Container {
    var myService: Factory<MyServiceProtocol> {
        self { @MainActor in MyService() }.singleton
    }
}

// Service definition
@Observable @MainActor
final class MyService: MyServiceProtocol {
    // state and logic
}
```

Rules:
- All service registrations go in `App/Container+App.swift` — never scatter them.
- Services are never accessed as singletons directly from views.

## Computed View Properties

**Never** use `private var foo: some View` computed properties inside screen or component files. These break SwiftUI's structural diffing and lead to performance issues.

```swift
// ❌ Wrong — computed view property
struct MeditationPlayerView: View {
    private var timerSection: some View {
        Text("00:00")
    }
}

// ✅ Correct — extract to a named View struct in Components/
struct MeditationTimerView: View {
    var body: some View {
        Text("00:00")
    }
}
```

Any non-trivial sub-view must be a separate `struct` in its own file under `Components/`.

## Swift Concurrency

Services must be `async throws`. ViewModels call them inside `Task { }`:

```swift
func toggleBlocking() {
    Task {
        do {
            try await blocker.toggle()
        } catch let error as ContactBlockerError {
            errorMessage = error.defaultDescription
        }
    }
}
```

Rules:
- Never use completion handlers for new service interfaces — use `async throws`
- `@MainActor` on the ViewModel class guarantees UI property updates run on the main thread
- Timer-based streams: prefer `AsyncTimerSequence` or `Task.sleep(for:)` loops over `Timer.publish`; Combine timer is acceptable only if already in place
- Never use `try?` to suppress errors from async calls — catch and surface them

## Task Storage and Cancellation

When a ViewModel can launch multiple sequential async operations (e.g. load on appear, refresh), cancel the previous task before launching a new one:

```swift
@Observable
final class SearchViewModel {
    var results: [Result] = []
    private var searchTask: Task<Void, Never>?

    func search(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            guard !Task.isCancelled else { return }
            results = await service.search(query: query)
        }
    }
}
```

Rules:
- Store tasks as `private var fooTask: Task<Void, Never>?`
- Cancel before re-launching when the operation is superseded
- Check `Task.isCancelled` at async boundaries for long operations

## Navigation — `NavigationStack`

Use `NavigationStack` with `NavigationPath` for programmatic navigation. Each feature defines its own route enum:

```swift
// Route enum per feature, lives in the feature folder (e.g. DashboardRoute.swift)
enum DashboardRoute: Hashable {
    case settings
    case unblockRequest
}

// In parent screen
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    DashboardHomeView(path: $path)
        .navigationDestination(for: DashboardRoute.self) { route in
            switch route {
            case .settings: SettingsScreen()
            case .unblockRequest: UnblockRequestScreen()
            }
        }
}
```

Rules:
- Do not use `NavigationView` — always `NavigationStack`
- Sheet presentations remain as-is (`.sheet(isPresented:)`)
- Route enums live in the feature folder (`DashboardRoute.swift`)
- Navigation state (`NavigationPath`) is owned by the root screen's `@State` or parent ViewModel

## Error Handling

Always define errors as enums conforming to `Error` with a `defaultDescription: String` computed property. List all error states exhaustively. Never use bare `String` or untyped `NSError` for domain errors.

**Pattern:**
```swift
enum MyFeatureError: Error {
    case caseA
    case caseB(Error)   // wraps underlying error when useful

    var defaultDescription: String {
        switch self {
        case .caseA: return "Human-readable message for A."
        case .caseB(let error): return "Failed: \(error.localizedDescription)"
        }
    }
}
```

- Throw the typed enum from services; catch in ViewModels
- ViewModels expose `var errorMessage: String?`; populate via `.defaultDescription`
- Never use `try?` to suppress errors — catch and surface them via the ViewModel

## SwiftLint

SwiftLint runs automatically as an Xcode build phase (`swiftlint --fix` then `swiftlint`). Key limits:

| Rule | Warning | Error |
|------|---------|-------|
| Line length | — | 130 chars |
| File length | 400 lines | 500 lines |
| Function body | 75 lines | — |
| Closure body | 100 lines | — |

### `empty_count` gotcha

The `empty_count` opt-in rule auto-converts `x.count > 0` → `!x.isEmpty`. For named tuples or custom types that lack `.isEmpty`, suppress with:

```swift
// swiftlint:disable:next empty_count
.someModifier(x.count > 0 ? a : b)
```

## Data Persistence

**No CoreData. No Firebase.** All persistence goes through `UserDefaultsService`.

- `NSUbiquitousKeyValueStore` (iCloud KVS) and App Group `UserDefaults` are accessed **only** via `UserDefaultsService` — never read/write them directly.
- Keys are defined in the `UserDefaultsKey` enum inside `UserDefaultsService`.
- `ProfileService` owns all read/write operations on `UserProfile` (root model containing `[CheckIn]`).

```swift
// ❌ Never access stores directly
UserDefaults(suiteName: "group.app.ddworks.FocusOnYourself")?.set(value, forKey: "foo")

// ✅ Always go through the service
userDefaultsService.store(value, for: .someKey)
```

## Widget Model Sync

The `FocusOnYourselfWidgets` target does **not** import main-target files. Widget-specific model copies live in `FocusOnYourselfWidgets/WidgetDataProvider.swift`.

**When modifying `CheckIn`, `Mood`, or `UserProfile`**, manually update the corresponding model copies in `WidgetDataProvider.swift` to keep them in sync.
