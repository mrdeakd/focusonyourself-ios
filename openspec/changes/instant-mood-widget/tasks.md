## 1. Widget Data Layer

- [x] 1.1 Add `static func logMood(_ rawValue: String)` to `WidgetDataProvider.swift`: decode App Group profile → upsert today's `WidgetCheckIn` (replace if dateString matches, append if new) → encode → write back to App Group UserDefaults
- [x] 1.2 Write a separate `"pendingWidgetCheckIn"` key (JSON: `{moodRawValue, dateString, timestamp}`) to App Group UserDefaults in the same `logMood` call, for the foreground merge path
- [x] 1.3 Add `static func pendingCheckIn() -> (moodRawValue: String, dateString: String, timestamp: Date)?` that reads and decodes the pending key
- [x] 1.4 Add `static func clearPendingCheckIn()` that removes the pending key from App Group UserDefaults
- [x] 1.5 Add `static var isOnboarded: Bool` to `WidgetDataProvider` that reads `onboardingCompleted` from the App Group UserDefaults profile

## 2. App Intents

- [x] 2.1 Create `FocusOnYourselfWidgets/LogMoodIntent.swift` conforming to `AppIntent` with `static let openAppWhenRun = false` and `static let isDiscoverable = false`
- [x] 2.2 Add `@Parameter(title: "Mood") var moodRawValue: String` to `LogMoodIntent`
- [x] 2.3 Implement `perform()`: call `WidgetDataProvider.logMood(moodRawValue)` then `WidgetCenter.shared.reloadAllTimelines()`, return `.result()`
- [x] 2.4 Create `OpenOnboardingIntent: AppIntent` in the same file with `static let openAppWhenRun = true` — used by the not-onboarded widget state's "Get Started" button

## 3. Widget Entry and Provider

- [x] 3.1 Create `FocusOnYourselfWidgets/CheckInWidget.swift` with `CheckInEntry: TimelineEntry` containing fields: `date`, `todaysMood: WidgetMood?`, `streak: Int`, `isStreakAtRisk: Bool`, `isOnboarded: Bool`
- [x] 3.2 Implement `CheckInProvider: AppIntentTimelineProvider` with `placeholder`, `snapshot`, and `timeline` methods (requires switching to `AppIntentConfiguration` — define a minimal `ConfigurationAppIntent` or use `EmptyAppIntentConfiguration`)
- [x] 3.3 In `CheckInProvider.timeline`: build two entries — a morning entry at `startOfDay + 7h` with `isStreakAtRisk: false`, and an evening entry at `startOfDay + 20h` with `isStreakAtRisk: true` only if `!WidgetDataProvider.hasCheckedInToday`; set policy to `.after(nextMidnight)`
- [x] 3.4 Populate `CheckInEntry` fields from `WidgetDataProvider`: `todaysMood`, `hasCheckedInToday`, `streakStats().current`, and `isOnboarded`

## 4. Widget View

- [x] 4.1 Implement `CheckInWidgetView` with a conditional branch: show `NotOnboardedView` when `!entry.isOnboarded`, show `LoggedView` when `entry.todaysMood != nil`, show `UnloggedView` otherwise
- [x] 4.2 Implement `UnloggedView`: header row with streak badge (flame + count in `foyOrange`) + "Log Mood" label + date label; mood row with five `Button(intent: LogMoodIntent(moodRawValue:))` pill buttons (warm greeting style from approved Option C design — greeting text top-left, navy streak pill top-right, "How's your [day]?" prompt, coloured pill buttons)
- [x] 4.3 Apply `.invalidatableContent()` to the streak counter text and the confirmation area so the shimmer fires immediately on tap
- [x] 4.4 Implement `LoggedView`: confirmed mood display, updated streak counter with `.contentTransition(.numericText())`, and a `Link` that deep-links to today's check-in detail in the app
- [x] 4.5 Apply at-risk visual treatment in `UnloggedView` when `entry.isStreakAtRisk`: reduce opacity or desaturate the streak flame icon
- [x] 4.6 Implement `NotOnboardedView`: brief "Set up FocusOnYourself" prompt and a `Button(intent: OpenOnboardingIntent())` labelled "Get Started →"
- [x] 4.7 Wrap all views in `.containerBackground(.background, for: .widget)` and verify the cream background (`foyBackground` / `#FAF8F5`) renders correctly

## 5. Widget Registration

- [x] 5.1 Define `CheckInWidget: Widget` with `kind: "CheckInWidget"`, `AppIntentConfiguration`, `supportedFamilies: [.systemMedium]`, display name "Check In", description "Log your daily mood in one tap."
- [x] 5.2 Add `CheckInWidget()` to `FocusOnYourselfWidgetsBundle` in `FocusOnYourselfWidgetsBundle.swift`

## 6. Main App — Foreground Merge

- [x] 6.1 Add `func mergeWidgetCheckIn()` to `ProfileService`: read `WidgetDataProvider.pendingCheckIn()` → if present and no existing check-in for that date in the profile (or widget timestamp is newer) → call `recordCheckIn(mood:feelingsDescription:)` → call `WidgetDataProvider.clearPendingCheckIn()`
- [x] 6.2 Add `.onChange(of: scenePhase)` in the app's root view (or `FocusOnYourselfApp`) that calls `profileService.mergeWidgetCheckIn()` when `scenePhase == .active`

## 7. Accessibility and Polish

- [x] 7.1 Add `.accessibilityLabel("Log mood: \(mood.displayName)")` to each mood button in `UnloggedView`
- [x] 7.2 Add `.accessibilityLabel("Current streak: \(entry.streak) days")` to the streak badge
- [ ] 7.3 Verify all interactive elements meet the 44×44pt minimum tap target size
- [ ] 7.4 Verify widget renders correctly in dark mode (test in Simulator with dark appearance)
- [ ] 7.5 Verify iOS 26 Liquid Glass accented rendering: confirm mood pill text and streak badge remain legible in accented widget mode

## 8. Build and Verify

- [x] 8.1 Build widget target with no errors or warnings: `xcodebuild -scheme FocusOnYourself -destination 'generic/platform=iOS Simulator' build`
- [x] 8.2 Run SwiftLint on new files: `swiftlint --fix && swiftlint`
- [ ] 8.3 Verify in Simulator: add CheckInWidget to home screen, tap a mood, confirm widget transitions to confirmed state without app launching
- [ ] 8.4 Verify in Simulator: foreground the app after a widget check-in, confirm the check-in appears in the History screen with the correct mood and streak
- [ ] 8.5 Verify existing MoodWidget and StreakWidget are unaffected (still appear and display correct data)
- [ ] 8.6 Verify at-risk state: set device clock to 8:01pm with no check-in and confirm the streak indicator is visually dimmed
