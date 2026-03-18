# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

**SwiftLint gotcha**: The `empty_count` opt-in rule auto-converts `x.count > 0` → `!x.isEmpty`. For named tuples or types without `.isEmpty`, suppress with:
```swift
// swiftlint:disable:next empty_count
.someModifier(x.count > 0 ? a : b)
```

Key limits: line length 130 (error), file length 400/500, function body 75 lines, closure body 100 lines.

## Architecture

**MVVM + Factory DI, iOS 17+, SwiftUI only.**

### Layers

| Layer | Location | Rule |
|-------|----------|------|
| Screens | `Features/*/` | Only a `@State private var viewModel = …ViewModel()` — no state, no logic |
| ViewModels | `Features/*/` | `@Observable @MainActor final class` — all state, all logic, calls services via Task |
| Services | `Services/` | `@Observable @MainActor` singletons registered in `Container+App.swift` |
| Models | `Models/` | Plain `Codable` structs/enums, no logic |
| Design System | `DesignSystem/` | Tokens only — `DS+Colors.swift`, `DS+Spacing.swift`, `DS+Typography.swift`, etc. |
| Components | `Features/*/Components/` or `DesignSystem/Components/` | Reusable views in their own files |

### Dependency Injection (Factory)

All services are registered as singletons in `Container+App.swift`. ViewModels inject via default parameters:

```swift
@Observable @MainActor final class HomeViewModel {
    @Injected(\.profileService) private var profileService
    @Injected(\.affirmationService) private var affirmationService
}
```

Views **never** call `Container.shared.resolve()`. Services are never accessed as singletons from views.

### Data Persistence

**No CoreData, no Firebase.** All data is JSON-serialized `Codable` structs stored in:
- `NSUbiquitousKeyValueStore` (iCloud KVS) — syncs across devices
- App Group UserDefaults (`group.app.ddworks.FocusOnYourself`) — shared with widgets

`UserDefaultsService` is the single abstraction over both stores. Keys are defined in a `UserDefaultsKey` enum inside that file.

The root model is `UserProfile` (contains `[CheckIn]`). `ProfileService` owns all read/write operations on it.

### Navigation

- Root (`ContentView`) switches between `OnboardingFlowView` and `MainTabView` based on `profileService.profile.onboardingCompleted`.
- `MainTabView` has 4 tabs driven by `AppTab` enum: Home, Meditate, History/Insights, Settings.
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
- `Models/UserProfile.swift` + `Models/CheckIn.swift` — core Codable models
- `DesignSystem/DS+Colors.swift` — full color token list
- `DesignSystem/DS+Spacing.swift` — spacing scale
- `FocusOnYourselfWidgets/WidgetDataProvider.swift` — widget data layer (keep in sync with main models)
