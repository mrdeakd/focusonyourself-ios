## Why

Returning users must unlock their phone, find the app, wait for it to load, and navigate to the check-in flow — five or more steps for a one-second mood decision. This friction causes daily check-ins to be skipped on busy or distracted days, breaking streaks and eroding the habit. iOS 17 App Intents made true one-tap in-widget action possible, and no mood-tracking competitor has shipped it yet.

## What Changes

- **New** `CheckInWidget` widget extension (kind: `"CheckInWidget"`, `.systemMedium`) — five interactive emoji mood buttons that log a check-in without opening the app
- **New** `LogMoodIntent: AppIntent` in the widget target — writes today's check-in to App Group UserDefaults as an upsert, then reloads widget timelines
- **New** `CheckInEntry` / `CheckInProvider` (`AppIntentTimelineProvider`) with two scheduled timeline states: morning prompt and evening "streak at risk" (after 8pm if no check-in)
- **New** `WidgetDataProvider.logMood(_:)` — adds write capability to the currently read-only provider
- **New** `ProfileService.mergeWidgetCheckIn()` — ingests widget-logged check-ins into iCloud KVS on next app foreground
- `FocusOnYourselfWidgets/FocusOnYourselfWidgetsBundle.swift` — registers `CheckInWidget`
- `FocusOnYourselfApp.swift` — adds `.onChange(of: scenePhase)` observer to trigger the foreground merge

The existing `MoodWidget` (read-only, `.systemSmall`) is unchanged.

## Capabilities

### New Capabilities
- `check-in-widget`: Interactive `.systemMedium` home screen widget with mood buttons, streak display, two timeline states (morning / evening at-risk), and foreground merge of widget-logged check-ins into the main app's iCloud KVS

### Modified Capabilities

## Impact

- **Widget target** (`FocusOnYourselfWidgets/`): 2 new files, 2 modified files
- **Main app** (`FocusOnYourself/`): `ProfileService.swift` + app lifecycle file modified
- **No new dependencies** — uses existing App Group, WidgetKit, and App Intents frameworks already available on iOS 17+
- **No breaking changes** — existing `MoodWidget` and `StreakWidget` are untouched
- **Data layer**: widget writes to App Group UserDefaults; main app promotes to `NSUbiquitousKeyValueStore` on foreground (eventual consistency across devices)
