---
name: writing-code
description: >
  ALWAYS load this skill automatically whenever writing, adding, or modifying any code file in this
  project. Enforces Swift/SwiftUI conventions, design system token usage, MVVM screen structure,
  component organization, dependency injection patterns, and error handling rules specific to
  the No More X codebase. Do not skip this skill for any code changes.
---

# Writing Code

## SwiftUI Views — Design System Tokens

When writing or modifying any SwiftUI view, **always use the design system constants** instead of raw values:

| What | Use | Never use |
|------|-----|-----------|
| Colors | `Color.nxPrimary`, `Color.nxBackground`, `Color.nxForeground`, etc. (`Colors.swift`) | `.blue`, `Color(hex:)`, `UIColor` literals |
| Spacing | `Spacing.xs/sm/md/lg/xl/xxl` (`Spacing.swift`) | `8`, `16`, `24` as magic numbers |
| Corner radius | `CornerRadius.*` (`CornerRadius.swift`) | `10`, `12`, `.cornerRadius(8)` |
| Typography | `.font(.nxLargeTitle)`, `.font(.nxHeadline)`, etc. (`Typography.swift`) | `.font(.system(size: 40))`, `.font(.title)` |

If a value has no matching token (e.g. a one-off icon size), extract it to a `private let` constant at the top of the struct — never leave magic numbers inline in the view body.

> **Text colors:** Use `Color.nxForeground` / `Color.nxForegroundSecondary` for primary and secondary text. `nxTextPrimary` / `nxTextSecondary` are deprecated backward-compat aliases — do not use them in new code.

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

## ViewModels — `@Observable`

All ViewModels use the `@Observable` macro. `ObservableObject` and `@Published` must **not** be used in new code. Existing ViewModels using `ObservableObject` must be migrated when touched.

```swift
// ✅ All ViewModels use @Observable
@Observable
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

Any UI piece used in more than one place — or likely to be reused — must be a separate `struct` in its own file under the nearest `Components/` folder.

- Do **not** inline ad-hoc sub-views inside screen files.
- Use `private struct` only for trivial, truly local layout helpers that have no reuse potential and would clutter a separate file.

```
Features/
  BlockSetup/
    BlockSetupScreen.swift
    BlockSetupViewModel.swift
    Components/
      AppRowView.swift      ✅ reusable row → own file
      SectionHeaderView.swift
```

## Dependency Injection

Services, managers, and handlers are resolved in the **ViewModel's `init`**, never in the view.

**Pattern:**
```swift
@Observable
final class BlockSetupViewModel {
    private let screenTimeService: ScreenTimeServicing
    private let analyticsService: AnalyticsServicing

    init(
        screenTimeService: ScreenTimeServicing = Container.shared.resolve(ScreenTimeServicing.self),
        analyticsService: AnalyticsServicing = Container.shared.resolve(AnalyticsServicing.self)
    ) {
        self.screenTimeService = screenTimeService
        self.analyticsService = analyticsService
    }
}
```

Rules:
- Views **never** call `Container.shared.resolve()` — that belongs exclusively in a ViewModel's `init`.
- `Container.shared` is allowed only to bootstrap ViewModels; services themselves are never accessed as singletons from views.
- `SharedDefaults` is for lightweight app-group persistence only; it must not be used as a substitute for injected services.

**Screens instantiate their ViewModel directly** — the ViewModel's `init` default parameters handle Container resolution:
```swift
// ✅ correct — ViewModel init pulls from Container via default params
@State private var viewModel = DashboardViewModel()
```

**Child ViewModels** owned by a parent ViewModel are direct `let` properties — no Container registration needed:
```swift
// ✅ correct — CooldownViewModel is a child, not a root-level service
let cooldownViewModel = CooldownViewModel()
```
Only root-level *services* (ContactBlocker, CooldownTimer, etc.) are registered in Container and resolved via init defaults.

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
- Display errors using the `NXErrorNotificationBanner` via the `.nxErrorBanner(message:)` modifier — the `message` parameter is a `Binding<String?>`:
  ```swift
  // ✅ correct — message is a Binding<String?>
  .nxErrorBanner(message: $viewModel.errorMessage)
  ```
