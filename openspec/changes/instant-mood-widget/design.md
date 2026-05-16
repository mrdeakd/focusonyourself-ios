## Context

The app currently has two read-only widgets (`MoodWidget`, `StreakWidget`) that display data from the App Group UserDefaults. `ProfileService.recordCheckIn()` already calls `WidgetCenter.shared.reloadAllTimelines()`. `WidgetDataProvider` reads from the App Group but has no write path. `UserDefaultsService.setData()` dual-writes to both `NSUbiquitousKeyValueStore` and App Group UserDefaults, so the App Group always reflects the latest in-app data.

The widget target cannot access `NSUbiquitousKeyValueStore` directly — it only has access to the App Group container. This asymmetry is the central architectural constraint for the sync path.

## Goals / Non-Goals

**Goals:**
- One-tap mood logging from `.systemMedium` home screen widget with no app launch
- Widget transitions to a confirmed state after logging (streak counter updates, mood buttons hidden)
- Two daily timeline states: morning prompt and evening "at-risk" (after 8pm if no check-in yet)
- Widget-logged check-ins promoted to iCloud KVS on next app foreground
- Existing `MoodWidget` and `StreakWidget` are completely unaffected

**Non-Goals:**
- Note or activity tagging from the widget (mood-only; user opens app to enrich)
- Multiple check-ins per day from the widget (re-logging requires opening the app)
- Small or large widget size variants in v1
- HealthKit `HKStateOfMind` write (separate future feature)
- Siri / App Intents voice integration

## Decisions

### 1. New `CheckInWidget` kind, not an extension of `MoodWidget`

`MoodWidget` uses `StaticConfiguration` with kind `"MoodWidget"`. Interactive buttons require `AppIntentConfiguration`. Switching the existing widget's configuration type would invalidate all existing user placements (iOS destroys and re-places the widget). A new kind `"CheckInWidget"` avoids this regression entirely. Users who want the interactive version add it freshly; existing MoodWidget placements continue working.

*Alternatives considered:* Migrate MoodWidget in-place — rejected because it silently removes the widget from every user's home screen on update.

### 2. `Button(intent:)` + `invalidatableContent()` rather than `Toggle`

`Toggle(isOn:intent:)` provides zero-latency optimistic rendering but models a binary on/off state. Mood selection is a 1-of-5 choice, which doesn't fit the Toggle semantic model. `Button(intent:)` is used per mood button. To mitigate the ~0.5s round-trip latency before the widget re-renders, the confirmation label and streak counter are marked with `.invalidatableContent()`, producing a shimmer immediately on tap.

*Alternatives considered:* One Toggle per mood (visual hack) — rejected as semantically wrong and likely to cause double-tap confusion.

### 3. Foreground merge for iCloud sync (Option A)

`LogMoodIntent.perform()` writes a `pendingWidgetCheckIn` key to App Group UserDefaults alongside the full profile update. On next app foreground, `ProfileService.mergeWidgetCheckIn()` reads this key, runs an upsert against the current iCloud KVS profile (replacing today's check-in if the widget entry is newer), then deletes the pending key.

*Option B considered:* Have the intent write the full profile back to both App Group and iCloud KVS — rejected because the widget process cannot access `NSUbiquitousKeyValueStore`, and writing a stale profile copy would clobber check-ins logged on other devices since the last foreground.

*Merge conflict rule:* If a check-in already exists for today in iCloud KVS, the widget entry wins only if `pendingWidgetCheckIn.timestamp > existing.timestamp`. This prevents a background widget intent from overwriting a more-recent in-app check-in.

### 4. Two timeline entries per day + intent-triggered free reload

The system grants ~40–70 passive timeline reloads per day. Scheduling more than a few entries wastes this budget and risks throttling. Two entries suffice:
- **Morning** (`startOfDay + 7h`): `isStreakAtRisk: false` — shows mood prompt with active streak
- **Evening** (`startOfDay + 20h`, i.e. 8pm): `isStreakAtRisk: true` if `!hasCheckedInToday` — streak icon dims

When `LogMoodIntent.perform()` completes, it calls `WidgetCenter.shared.reloadAllTimelines()`. This reload is free (does not consume the passive budget) and immediately shows the confirmed state.

### 5. `WidgetDataProvider` gains a write function; `WidgetCheckIn` stays private

`WidgetCheckIn` and `WidgetUserProfile` are private types in `WidgetDataProvider.swift`. Rather than exposing them, the new `static func logMood(_ rawValue: String)` function encapsulates the full read-modify-write in one place: decode profile from App Group → upsert today's check-in → encode → write back. This keeps the widget target's data layer self-contained with a single write site.

## Risks / Trade-offs

**Cross-device check-in window** → If a user logs via widget on device A, then opens device B before ever foregrounding device A, device B's iCloud KVS data wins and the widget check-in is lost. *Mitigation:* The pending key persists until device A's app is foregrounded, so the check-in is not lost — it just hasn't synced yet. Acceptable for a mood log where eventual consistency is sufficient.

**Widget height constraint** → A `.systemMedium` widget gives ~133pt of usable vertical space (165pt minus 32pt padding). Five mood buttons with labels must fit in a single row. At 44pt circles with 10pt labels, the row is ~60pt — tight but validated in the Pencil mockup. If future designs add a third row, the widget height would need to change.

**`openAppWhenRun` guard for onboarding** → If `openAppWhenRun` is accidentally set to `true`, every tap opens the app and defeats the feature. This must be an explicit `static let openAppWhenRun = false` constant, not a default.

## Migration Plan

No data migration required. `CheckInWidget` is additive — it doesn't replace any existing widget or data structure. Deploy as a standard App Store update. Users who want the interactive widget add it from the Widget Gallery; the existing MoodWidget and StreakWidget placements are unaffected.

Rollback: remove `CheckInWidget` from the bundle and ship an update — existing placements simply disappear from home screens (standard widget removal behaviour).

## Open Questions

None. All 9 decisions were resolved during the feature spec Q&A session.
