# FocusOnYourself

A daily mood tracking and wellness app for iOS. Log your mood in seconds, discover what affects it, meditate, and build an unbroken streak — all from your home screen.

---

## Features

- **Daily check-in** — One-tap mood logging (5 levels) with optional journal entry and context factors (sleep, stress, exercise, social quality)
- **Home screen widget** — Log your mood directly from the iOS widget without opening the app, powered by AppIntents
- **Affirmations** — Personalized daily affirmations generated on-device with Apple Intelligence or fetched from the backend
- **Meditation** — Guided sessions with narration, silence timers, and bell cues across Morning, Focus, Anxiety, and Sleep categories
- **Insights** — 7-day mood chart, weekly/monthly averages, Pearson correlation analysis to reveal which daily factors move your mood, and mood distribution breakdown
- **History** — Monthly calendar heatmap of check-in streaks with day-detail sheets
- **HealthKit** — Writes each check-in to Apple Health as a StateOfMind entry (iOS 18+)
- **iCloud sync** — Check-in history syncs across all your devices via NSUbiquitousKeyValueStore
- **Pro tier** — Unlocks premium meditation sessions, 30-day trend charts, Apple Intelligence affirmations, and all affirmation categories

---

## Tech Stack

### Platform
| Technology | Usage |
|-----------|-------|
| **Swift 6 / SwiftUI** | Entire UI, iOS 17+ deployment target |
| **Swift Concurrency** (`async`/`await`, `@MainActor`, actors) | All service calls and background work |
| **Swift Charts** | Mood trend charts, bar charts, correlation ranking |
| **SwiftData / UserDefaults** | — |
| **NSUbiquitousKeyValueStore** | iCloud KVS for cross-device profile sync |
| **App Group UserDefaults** | Shared storage between app and widget targets |

### Apple Frameworks
| Framework | Usage |
|-----------|-------|
| [**WidgetKit**](https://developer.apple.com/documentation/widgetkit) | Streak widget, mood widget, interactive check-in widget |
| [**AppIntents**](https://developer.apple.com/documentation/appintents) | `LogMoodIntent` — logs mood from widget without opening the app |
| [**HealthKit**](https://developer.apple.com/documentation/healthkit) | Writes `HKStateOfMind` samples on check-in (iOS 18+) |
| [**StoreKit 2**](https://developer.apple.com/documentation/storekit) | Auto-renewable subscriptions (monthly + annual), transaction verification |
| [**Foundation Models**](https://developer.apple.com/documentation/foundationmodels) | On-device affirmation generation via Apple Intelligence (`LanguageModelSession`) |
| [**AVFoundation**](https://developer.apple.com/documentation/avfoundation) | Meditation narration playback (MP3) + procedurally generated bell sound |
| [**UserNotifications**](https://developer.apple.com/documentation/usernotifications) | Daily 9 AM check-in reminder |

### Third-Party Libraries
| Library | Usage |
|---------|-------|
| [**Factory**](https://github.com/hmlongco/Factory) | Compile-time dependency injection with `@Injected` property wrapper |

### Backend
| Service | Usage |
|---------|-------|
| **REST API** (Render) | Daily articles, meditation sessions, affirmation batches |
| **URLSession** | Networking layer (`URLSessionNetworkClient`) |

### Tooling
| Tool | Usage |
|------|-------|
| [**SwiftLint**](https://github.com/realm/SwiftLint) | Enforced style rules, zero violations required |
| **Xcode 16** (filesystem-synchronized groups) | Auto-discovers new Swift files without pbxproj edits |

---

## Architecture

**MVVM + Factory DI**, strict separation of concerns:

```
Screen (View)
  └── ViewModel (@Observable @MainActor)
        └── Services (@Observable @MainActor singletons)
              └── Persistence (iCloud KVS + App Group UserDefaults)
```

- **Screens** hold only `@State private var viewModel = …ViewModel()` — no logic, no extra state
- **ViewModels** own all state (including sheet/navigation booleans) and call services via `Task {}`
- **Services** are `async throws`, registered as singletons in `Container+App.swift` via Factory
- **Models** are plain `Codable` structs — no logic, no framework coupling
- **Design System** (`DesignSystem/`) provides spacing, color, typography, and corner-radius tokens — no raw values in views

---

## Project Structure

```
FocusOnYourself/
├── App/                        # Entry point, tab bar, DI container
├── DesignSystem/               # DS+Colors, DS+Spacing, DS+Typography, DS+CornerRadius
│   └── Components/             # Reusable design-system views (ErrorInfo, SheetHeader…)
├── Features/
│   ├── Home/                   # Daily check-in, mood picker, affirmations, articles
│   ├── Meditate/               # Session browser, meditation player
│   ├── HistoryInsights/        # Segmented controller host (History + Insights)
│   ├── History/                # Calendar heatmap, day detail sheet
│   ├── Insights/               # Charts, factor correlation, mood breakdown
│   ├── Onboarding/             # 4-step onboarding flow
│   ├── Paywall/                # StoreKit 2 subscription screen
│   └── Settings/               # Profile, categories, notifications, appearance
├── Models/                     # CheckIn, CheckInFactors, UserProfile, Mood, Article…
├── Networking/                 # NetworkClientProtocol, URLSessionNetworkClient
├── Services/                   # ProfileService, AffirmationService, PurchaseService…
└── Extensions/                 # Date formatting, Bundle JSON decoding

FocusOnYourselfWidgets/
├── CheckInWidget.swift         # Interactive mood-logging widget (AppIntents)
├── MoodWidget.swift            # Today's mood display widget
├── StreakWidget.swift          # Current streak display widget
└── WidgetDataProvider.swift    # Shared App Group data layer

openspec/changes/               # Feature change specifications
specification/                  # Product specs
design-tokens/                  # Exported design token JSON (light/dark/primitives)
```

---

## Requirements

- **Xcode 16+**
- **iOS 17+** (deployment target)
- **iOS 18+** for HealthKit StateOfMind and Apple Intelligence features
- Swift 6 strict concurrency

## Build

```bash
xcodebuild -project FocusOnYourself.xcodeproj \
  -scheme FocusOnYourself \
  -destination 'generic/platform=iOS Simulator' \
  build
```

```bash
swiftlint --fix && swiftlint   # must report 0 violations
```
