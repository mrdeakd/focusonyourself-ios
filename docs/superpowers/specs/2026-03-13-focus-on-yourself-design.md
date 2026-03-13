# Focus On Yourself — Design Spec

**Date:** 2026-03-13
**Platform:** iOS (SwiftUI)
**Status:** Approved

---

## 1. Overview

Focus On Yourself is an iOS wellness app centered on daily affirmations and streak-based habit building. Users complete a short daily check-in — read today's affirmation and rate their mood — to maintain their streak. Affirmations are curated, filtered by categories chosen during onboarding. On supported devices (iOS 26+ / iPhone 15 Pro or newer), Apple Intelligence generates personalized affirmations as a bonus. All data is stored locally via UserDefaults and SwiftData, synced to iCloud.

**Target audience:** General wellness users interested in mental health, mindfulness, and self-improvement.

**Non-goals (v1):**
- No user accounts or backend
- No social features
- No custom user-written affirmations
- No Claude/OpenAI API usage

---

## 2. Screens & Navigation

### Onboarding (shown once, first launch)

1. **WelcomeScreen** — App name, tagline, brief pitch
2. **NameEntryScreen** — "What should we call you?" (used for personalized greetings)
3. **CategoryPickerScreen** — Multi-select from 4 categories; at least one required. The "Continue" button is disabled until at least one category is selected (UI-level validation in `CategoryPickerScreen`).
4. **NotificationPermissionScreen** — Explains 9am daily reminder, requests `UNUserNotificationCenter` permission

Onboarding completion is tracked in UserDefaults (`onboardingCompleted: Bool`). Once set, app launches directly into the main tab view.

### Main App (Tab bar — 3 tabs)

| Tab | Screen | Purpose |
|-----|--------|---------|
| Home | `HomeScreen` | Greeting, today's affirmation, mood check-in, compact streak badge |
| History | `HistoryScreen` | Calendar heatmap, current + longest streak stats |
| Settings | `SettingsScreen` | Edit name, change categories, notification toggle, Apple Intelligence toggle (hidden on unsupported devices) |

---

## 3. Data Model

### UserProfile (UserDefaults + iCloud KV Store)

```swift
name: String
selectedCategories: [Category]
notificationsEnabled: Bool
appleIntelligenceEnabled: Bool
onboardingCompleted: Bool
```

### DailyCheckIn (SwiftData + CloudKit)

```swift
date: Date         // calendar day, normalized to midnight — used for streak computation
affirmationID: String
mood: Int          // 1–5
completedAt: Date  // wall-clock timestamp of when check-in was submitted
```

`DailyCheckIn` records are never written to `NSUbiquitousKeyValueStore` — they sync exclusively via CloudKit through SwiftData's CloudKit integration.

### Affirmation (bundled JSON — `affirmations.json`)

```swift
id: String
text: String
author: String?    // optional attribution
categories: [Category]
```

### Category (enum)

```swift
.confidence   // Confidence & self-worth
.health       // Health & body
.relationships // Relationships & love
.mindfulness  // Mindfulness & calm
```

### Streak (derived, not stored)

Computed by `StreakService` by walking backwards through `DailyCheckIn` records from today. A streak day = any calendar day with at least one completed check-in.

Rules:
- **Before today's check-in is done**: streak = consecutive days ending at yesterday (e.g. if user checked in 3 days in a row including yesterday, streak shows 3)
- **After today's check-in is done**: streak = consecutive days ending today (previous 3 + today = 4)
- **New user, day 1, no check-in yet**: streak shows 0
- **New user, day 1, after check-in**: streak shows 1
- **Missed a day**: streak resets to 0 (no yesterday check-in and today's isn't done yet)

---

## 4. Affirmation Selection

- Affirmations are stored in a bundled `affirmations.json` file
- Today's affirmation is selected deterministically by `date + user's selected categories` — the same affirmation displays all day, changes at midnight
- The selection algorithm: filter affirmations matching any of the user's selected categories, then use `dayOfYear % filteredCount` as a stable index (leap year day 366 is handled by the modulo — no special case needed). Yearly repetition (same date = same affirmation each year) is acceptable in v1.
- The affirmation is computed once and cached in `AppState` at app launch (or when categories change in Settings). If the user changes categories mid-day, the affirmation updates to reflect the new selection.
- No network calls required

---

## 5. Apple Intelligence Integration

- Uses Apple's `FoundationModels` framework (iOS 26+)
- Availability: iOS 26+ / iPhone 15 Pro or newer
- After completing a mood check-in, the app optionally shows an AI-generated affirmation personalized to the selected mood
- The AI affirmation is **ephemeral** — displayed inline after check-in completion, not persisted to storage or `DailyCheckIn`. Rendered by a new `AIAffirmationView` component under `Home/Components/`.
- Prompt design (the exact template passed to `FoundationModels`) is deferred to the implementation phase of step 8.
- Enabled via a toggle in Settings (hidden entirely on unsupported devices)
- Falls back gracefully to curated affirmations on unsupported devices — no crash, no error message shown

---

## 6. Streak Logic

- **Check-in = streak day**: Any day with a completed `DailyCheckIn` counts
- **Streak computation**: `StreakService` counts consecutive days ending today (or yesterday, if today's check-in isn't done yet)
- **Reset**: Missing a calendar day resets streak to 0
- **Longest streak**: `StreakService` also computes the longest-ever streak by scanning all `DailyCheckIn` records for the longest consecutive-day chain
- **Midnight rollover**: `StreakService` evaluates streak once per app foreground event (not on a real-time timer) to avoid mid-midnight flicker
- **HomeScreen streak component**: Compact flame icon + day count (e.g. "🔥 12 days")
- **HistoryScreen streak component**: Expanded calendar heatmap view + "Current streak: X days" + "Longest streak: Y days" stats

---

## 7. Notifications

- Daily trigger at 9:00am, user's local timezone
- Notification title: `"Good morning, [name] ✨"` — body: `"Your daily affirmation is ready. Take a moment for yourself."`
- Scheduled via `UNUserNotificationCenter` as a repeating `DateComponents`-based trigger
- Requested during onboarding (NotificationPermissionScreen)
- If user denies: app functions normally, no notification, streak still possible
- Toggle in Settings: if permission was previously granted, toggle cancels/reschedules the notification. If permission was previously **denied**, tapping the toggle opens `UIApplication.openSettingsURLString` to direct the user to iOS Settings — `requestAuthorization` is not re-called (iOS prevents it after denial)
- Rescheduled automatically if user re-enables from Settings

---

## 8. Storage Strategy

| Data | Storage | Sync |
|------|---------|------|
| UserProfile fields | `UserDefaults` | `NSUbiquitousKeyValueStore` (iCloud KV) |
| DailyCheckIn records | `SwiftData` | CloudKit (via SwiftData's CloudKit sync) |
| Affirmations | Bundled JSON | None (read-only) |

---

## 9. Code Structure

```
FocusOnYourself/
├── App/
│   ├── FocusOnYourselfApp.swift
│   └── AppState.swift              // @Observable, holds streak, profile, today's affirmation
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingCoordinator.swift
│   │   ├── WelcomeScreen.swift
│   │   ├── NameEntryScreen.swift
│   │   ├── CategoryPickerScreen.swift
│   │   └── NotificationPermissionScreen.swift
│   ├── Home/
│   │   ├── HomeScreen.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   │       ├── AffirmationCardView.swift
│   │       ├── MoodCheckInView.swift
│   │       └── StreakBadgeView.swift
│   ├── History/
│   │   ├── HistoryScreen.swift
│   │   ├── HistoryViewModel.swift
│   │   └── Components/
│   │       └── StreakCalendarView.swift
│   └── Settings/
│       ├── SettingsScreen.swift
│       └── SettingsViewModel.swift
├── Models/
│   ├── UserProfile.swift
│   ├── Affirmation.swift
│   ├── DailyCheckIn.swift
│   └── Category.swift
├── Services/
│   ├── AffirmationService.swift    // loads JSON, selects daily affirmation
│   ├── StreakService.swift         // computes streak from check-in records
│   ├── NotificationService.swift  // schedules 9am daily notification
│   ├── StorageService.swift       // UserDefaults + SwiftData + iCloud sync
│   └── IntelligenceService.swift  // FoundationModels calls (iOS 26+, no-op on older OS)
└── Resources/
    └── affirmations.json
```

**Architecture:** MVVM with SwiftUI. Each screen has a paired `@Observable` ViewModel. Shared state lives in `AppState`, injected via `.environment` from `FocusOnYourselfApp`.

**StorageService role:** `StorageService` is a thin coordinator — it owns `UserDefaults` reads/writes and the `NSUbiquitousKeyValueStore` sync layer. SwiftData's `ModelContainer` is configured in `FocusOnYourselfApp` and passed into the environment; `DailyCheckIn` records are accessed directly via `@Query` / `ModelContext` in ViewModels. `StorageService` does not wrap SwiftData operations.

---

## 10. Implementation Order

1. Onboarding flow (start here — design in Pencil.dev first)
2. Core data models + StorageService (+ configure iCloud/CloudKit entitlements early)
3. AffirmationService + affirmations.json content
4. HomeScreen (affirmation card + mood check-in + streak badge)
5. StreakService + HistoryScreen
6. NotificationService
7. SettingsScreen
8. Apple Intelligence integration (IntelligenceService + FoundationModels)
