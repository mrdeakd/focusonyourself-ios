# Instant Mood Widget Specification

**Status:** Draft  
**Created:** 2026-05-15  
**Feature:** A medium-size interactive home screen widget with 5 mood buttons. Tap a mood → check-in logged. No app launch, no friction.

---

## Discovery Context

**How this was identified:** Confirmed market gap — no mood-tracking app offers true in-widget mood selection as of 2025. Streaks proves the iOS 17 App Intents framework supports exactly this pattern for habits. Daylio, Moodistory, MoodFlow AI, and Moodistory all use widgets only as deep-links into the app. Bearable's interactive widget has been the #1 feature request for 4+ years without delivery. Cross-referenced with user pain point research: "missing widget / offline support" is the #10 most-cited complaint, and friction-at-check-in is the primary cause of abandonment (96% of users quit within 15 days).  
**Complexity estimate:** Medium  
**Impact estimate:** High

---

## Problem Statement

Returning users who want to log their mood must unlock their phone, find and tap the app icon, wait for it to load, navigate to the check-in flow, and tap their mood — five to seven steps for a one-second decision. This friction is the primary reason habitual check-in streaks break: users skip logging on busy or distracted days not because they don't want to, but because the activation energy is too high.

A home screen widget with interactive mood buttons collapses this to a single tap from the home screen. The check-in completes without the app ever launching. This makes the daily mood log as frictionless as marking a calendar event done — and research on habit formation confirms that reducing activation energy is the single highest-leverage lever for daily retention.

---

## Research Findings

### What Similar Apps Do

**Streaks (Crunchy Bagel)** — Gold standard for interactive habit widgets. The "Tasks Widget" (medium/large, iOS 17+) shows up to 4 habits as cards with interactive checkmark buttons. Tapping marks the habit complete without opening the app; the widget updates in-place. Supports `.systemSmall`, `.systemMedium`, `.systemLarge`. Uses `Button(intent:)` with `openAppWhenRun = false`. Clean, icon-forward, monochrome-tinted in iOS 18.

**Daylio** — Small and medium widgets available, but both are deep-links that open the app to the entry screen. The 5-emoji mood selection is not available in-widget. Most-requested missing feature in community boards. The app's entry flow itself is fast (2 taps after launch), but launch latency still breaks the habit loop.

**Gentler Streak** — Multiple widget types (Activity Status, Single Health Metric, Various Metrics) but all fully passive — tapping opens the app. Excellent passive information density (sparkline trends, status labels), but zero interactive completion.

**Finch** — Small widget showing the user's custom bird and an adventure progress bar. Purely emotional/presence widget — no action possible. Uses gamified visual attachment (the specific customized bird) as the tap trigger. High D1/D7 retention from the emotional layer alone, despite requiring app launch for all actions.

**Moodistory** — Five distinct widget types including a 14-day sparkline trend widget and a Positive Moments photo widget. All are informational. Quick Entry widget is a deep-link. No interactive mood selection.

**Bearable** — Zero widgets exist as of 2025, despite it being the #1 user request for 4+ years. Demonstrates that widget development is chronically deprioritized in this category, and that shipping first is a meaningful differentiator.

**MoodFlow AI (2024)** — Small and medium display widgets (emoji + label for today's mood). Purely informational; no interaction.

**The gap:** Not a single major mood-tracking or mindfulness app lets users tap a mood option directly from a home screen widget without opening the app. This is a clear first-mover window.

### UX Patterns & Best Practices

**Toggle-First Optimistic Completion** — For binary completion states (checked-in / not checked-in), `Toggle(isOn:intent:)` pre-renders both states at archive time and flips visually the instant the user taps, before the App Intent round-trip completes. This eliminates perceived latency. For mood selection (5 distinct options), `Button(intent:)` is used per mood, paired with `invalidatableContent()` on the confirmation area to show a shimmer while the intent processes.

**Glanceable State + Single Decision Surface** — Show only what's needed to motivate the tap: streak count, today's date, and the 5 mood buttons. No history charts, no explanatory text, no settings. The widget's job is to lower activation energy to near zero, not to summarize the app.

**`invalidatableContent` + Transition as Completion Ceremony** — Mark the confirmation label and streak counter with `.invalidatableContent()`. When the intent fires, the system shimmers those views immediately (acknowledging receipt), then the timeline reloads and new content fades/slides in. This two-phase micro-ceremony maps to the psychological cue → routine → reward loop: shimmer triggers anticipation, confirmed state delivers the reward.

**Streak Visibility** — Display the current streak count prominently as a lightweight "🔥 N" indicator. No at-risk state, no evening complexity — just a persistent motivational signal.

**Progressive Size Disclosure** — Medium only (≈393×169pt). Enough room for 5 interactive mood buttons in a row with a minimal header above. Clean, single-purpose.

### Anti-Patterns to Avoid

**The Mini-App Widget** — Cramming history charts, insights, and entry form into a single widget. Information overload at the cue moment causes decision paralysis and habit abandonment. The widget must do one thing.

**Aggressive Timeline Polling** — Scheduling reloads every 5–10 minutes or calling `WidgetCenter.shared.reloadAllTimelines()` throughout the app lifecycle. The system throttles widgets exceeding ~40–70 reloads/day. Use: one entry per day + midnight refresh + free intent-triggered reload on tap.

**Silent Failure / Tap Ambiguity** — Using `Button` without `invalidatableContent()` leaves a 0.5–1 second gap between tap and visual response with no intermediate feedback. Users tap again, causing double-logging. Always pair `Button(intent:)` with `invalidatableContent()` on the primary value, or use a `Toggle` for binary states.

### Technical Considerations

**Existing foundations (all already in place):**
- App Group `group.app.ddworks.FocusOnYourself` provisioned in both entitlements
- `UserDefaultsService.setData()` dual-writes to both `NSUbiquitousKeyValueStore` and App Group `UserDefaults`
- `WidgetDataProvider` reads from App Group UserDefaults with key `"userProfile"`, using `WidgetCheckIn` / `WidgetUserProfile` private structs
- `ProfileService.recordCheckIn()` already calls `WidgetCenter.shared.reloadAllTimelines()`
- `WidgetMood` and `Mood` have identical `rawValue` strings — JSON round-trip compatible

**New work required:**

1. **`LogMoodIntent`** — New `AppIntent` in the widget target with `openAppWhenRun = false`, `moodRawValue: String` parameter, writes to App Group UserDefaults as an upsert for today's check-in, then calls `WidgetCenter.shared.reloadAllTimelines()`.

2. **`WidgetDataProvider.logMood(_:)`** — New static write function that mirrors `ProfileService.recordCheckIn` logic: load profile from App Group → upsert today's `WidgetCheckIn` → encode → write back to App Group. Must handle the case where today's check-in already exists (replace, not append).

3. **New `CheckInWidget` kind** — Separate from the existing `MoodWidget` (kind: `"MoodWidget"`). Creating a new kind avoids regression for existing users who have placed the current MoodWidget. Provider uses `AppIntentConfiguration` / `AppIntentTimelineProvider` (not `StaticConfiguration`).

4. **`CheckInEntry`** — New `TimelineEntry` with fields: `date`, `todaysMood: WidgetMood?`, `streak: Int`, `isOnboarded: Bool`. No at-risk state.

5. **`CheckInProvider`** — `AppIntentTimelineProvider` that delivers one entry (current state) with `.after(midnight)` policy. Intent tap triggers a free reload.

6. **Main app foreground merge** — `ProfileService` needs a `mergeWidgetCheckIn()` function triggered via `.onChange(of: scenePhase)` when the app returns to `.active`. It reads the App Group `UserDefaults` for any `pendingWidgetCheckIn` key the intent wrote, merges it into the iCloud KVS profile if newer than the current stored check-in for that date, then clears the pending key. This is the only path to get widget-logged check-ins into iCloud sync.

7. **Onboarding guard** — The widget intent should check if onboarding is complete. If not, set `openAppWhenRun = true` and use `.openApp` result to route into onboarding.

**iOS 26 Liquid Glass note:** Widget backgrounds may adopt accented rendering under iOS 26. Use `.containerBackground(.background, for: .widget)` and verify the mood emoji buttons remain readable in both accent and full-color modes.

**Memory limit:** Widget extension must stay under 30 MB. JSON profile is well under 50 KB — no concern.

---

## User Stories

- As a daily user, I want to tap my mood directly from the home screen so I can log a check-in in one gesture without opening the app.
- As a returning user, I want to see my current streak count in the widget so I have a lightweight motivational signal.
- As a user who already logged today, I want the widget to show my logged mood and "Logged ✓" so I know it saved.
- As a first-time user who hasn't completed onboarding, I want the widget to prompt me to open the app so I can finish setup.
- As a power user who switches devices, I want my widget-logged check-ins to sync to iCloud so they appear on my other device when I next open the app.
- As a dark-mode user, I want the widget to render correctly in dark mode.

---

## Functional Requirements

### Must Have (launch blocker)
- [x] Medium-size (`.systemMedium`) CheckInWidget with 5 interactive mood buttons (rough, low, okay, good, great) using `Button(intent:)` with `openAppWhenRun = false`
- [x] `LogMoodIntent` writes today's check-in to App Group UserDefaults (upsert semantics — replace if today already exists)
- [x] Widget transitions from "log mood" state to confirmed state showing the logged mood and "Logged ✓" without opening the app
- [x] `invalidatableContent()` applied to header and confirmation area for shimmer feedback during intent round-trip
- [x] Streak count shown as a "🔥 N" indicator in both states
- [x] Main app `ProfileService.mergeWidgetCheckIn()` ingests widget-logged check-ins into iCloud KVS on app foreground
- [x] Onboarding guard: if profile not complete, widget shows a "Get Started →" button that opens the app
- [x] Widget registered in `FocusOnYourselfWidgetsBundle` with kind `"CheckInWidget"`
- [x] Renders correctly in light and dark mode via SwiftUI adaptive colors

### Should Have (high value, not blocking)
- [x] Streak counter uses `.contentTransition(.numericText())` for animated increment on tap
- [x] Accessibility labels on all mood buttons and streak indicator

### Could Have (nice-to-have)
- [ ] StandBy / Lock Screen `.accessoryRectangular` variant
- [ ] HealthKit `HKStateOfMind` write on foreground merge (separate feature)

### Won't Have (explicitly out of scope this version)
- Note/activity entry from the widget (mood-only; notes are added by opening the app after logging)
- Multiple mood logs per day from the widget (first log of day only; re-log by opening app)
- Siri / Shortcuts integration for voice check-in (separate feature)
- HealthKit `HKStateOfMind` write from the widget (separate feature; write happens in main app on foreground merge)

---

## Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| Performance | Intent `perform()` completes in under 200ms (JSON decode → upsert → encode → write on App Group UserDefaults); no network calls in intent |
| Accessibility | Each mood button has `.accessibilityLabel` ("Log mood: Rough" etc.); streak counter has descriptive label ("Current streak: 7 days"); minimum tap target 44×44pt |
| Offline | Fully offline — writes to App Group UserDefaults locally; iCloud sync happens when main app foregrounds |
| iCloud sync | Widget writes to App Group only; `ProfileService.mergeWidgetCheckIn()` promotes to iCloud KVS on next app foreground |
| Widget impact | New `CheckInWidget` added; existing `MoodWidget` (`.systemSmall`, read-only display) is unchanged |
| Privacy | No sensitive data beyond mood (user-reported, not HealthKit); no network calls from widget; no analytics from intent |
| Notifications | No new notification permissions required |

---

## Design Requirements

**Affected screens:** None existing — widget is a new surface  
**New screens needed:** None — widget only  
**Navigation entry point:** iOS home screen Widget Gallery → "FocusOnYourself" section → "Check In" widget

**Medium widget layout (393×169pt):**

```
Unlogged state:
┌─────────────────────────────────────────────┐
│  How are you feeling?              🔥 12    │
│                                              │
│  [😩]    [😔]    [😐]    [😊]    [🤩]      │
│  Rough    Low    Okay   Good   Great        │
└─────────────────────────────────────────────┘

Confirmed state:
┌─────────────────────────────────────────────┐
│  Today's mood                      🔥 13    │
│                                              │
│  😊  Good                                   │
│      Logged ✓                               │
└─────────────────────────────────────────────┘
```

**Key design constraints:**
- Widget background: `.containerBackground(.background, for: .widget)` — system adaptive
- Streak: `foyOrange` (#FF6B2B) using raw `Color(red:green:blue:)` in widget target
- Mood buttons: emoji + label in a rounded rect with `Color.secondary.opacity(0.12)` background (adaptive)
- Typography: system font at widget scale (not `.foy*` tokens)
- No at-risk state, no evening complexity, no deep-link

**Animation/transition expectations:** `.contentTransition(.numericText())` on streak counter; `.invalidatableContent()` shimmer on header and confirmation area while intent processes.

---

## Resolved Open Questions

| # | Question | Answer | Decision |
|---|----------|--------|----------|
| 1 | What widget sizes ship in v1? | Medium only | Single `.systemMedium` with 5 mood buttons; no small or large variant in v1 |
| 2 | Mood representation? | Emoji faces | Use `mood-*` image assets (existing `WidgetMood.imageName`) — matches app visual language |
| 3 | Already logged today — what shows? | Confirmation state with edit tap | Show logged mood + updated streak + "Tap to add a note →" link that opens app to today's detail |
| 4 | Show streak in widget? | Yes, prominently | Streak count in top-left; dims at 8pm on unchecked days |
| 5 | Mood + activity or mood-only? | Mood-only | One-tap log; notes/activities via app after logging |
| 6 | New widget kind or extend MoodWidget? | New CheckInWidget | Kind: `"CheckInWidget"`; existing `MoodWidget` (kind: `"MoodWidget"`) unchanged |
| 7 | Onboarding edge case | Deep-link into onboarding | If `!profile.onboardingCompleted`, intent uses `openAppWhenRun = true` and routes to onboarding |
| 8 | Timeline states | Single entry + midnight reset | One entry per day; intent tap triggers a free reload; no morning/evening split |
| 9 | Success metric | Daily check-in rate increases | Primary metric: % of users logging at least once per day (target: measurable lift from widget adoption) |

---

## Design Options

Three design variants are in Pencil:

| Option | Name | Rationale |
|--------|------|-----------|
| A | Streak-Forward | Streak counter is the hero element; neutral circles + text labels mirror Streaks app aesthetic and maximize familiarity with habit-tracker conventions |
| B | Mood-First | Larger colored emoji circles without text labels put the emotional decision front-and-center; "How are you today?" prompt replaces the app title for a more conversational feel |
| C | Warm Greeting | Contextual morning greeting + labeled color pill buttons create a warmer, more narrative feel that differs most from standard habit-tracker conventions |

**Pencil location:** `FocusOnYourselfDesign.pen` → Widget Designs frame → "CheckIn Widget — Approved"  
**Approved option:** Option C (simplified) — clean mood picker, no greeting/weekday complexity  
**Status:** ✅ Implemented.

---

## Implementation Notes

**Files to create:**
- `FocusOnYourselfWidgets/CheckInWidget.swift` — Widget, View, `CheckInEntry`, `CheckInProvider` (AppIntentTimelineProvider)
- `FocusOnYourselfWidgets/LogMoodIntent.swift` — `LogMoodIntent: AppIntent`
- Update `WidgetDataProvider.swift` — add `static func logMood(_ rawValue: String)` write function

**Files to modify:**
- `FocusOnYourselfWidgets/FocusOnYourselfWidgetsBundle.swift` — register `CheckInWidget`
- `FocusOnYourself/Services/ProfileService.swift` — add `mergeWidgetCheckIn()` function
- `FocusOnYourself/App/FocusOnYourselfApp.swift` (or root ContentView) — add `.onChange(of: scenePhase)` to call `profileService.mergeWidgetCheckIn()` on `.active`

**Models:** No changes to `CheckIn`, `Mood`, or `UserProfile` needed. `WidgetCheckIn` / `WidgetUserProfile` in `WidgetDataProvider.swift` are already correct; just add the write function.

**Widget kind:** `"CheckInWidget"` — do NOT reuse `"MoodWidget"` to avoid breaking existing user widget placements.

**iCloud sync merge strategy:**
```
mergeWidgetCheckIn():
  1. Read pendingWidgetCheckIn from App Group UserDefaults
  2. If present and no existing check-in for that dateString in KVS profile (or widget check-in is newer):
     → call recordCheckIn(mood:feelingsDescription:) with widget data
  3. Delete pendingWidgetCheckIn key from App Group
```

**Navigation:** Tapping the confirmed widget state should deep-link to today's check-in detail. Use a `Link(destination: URL(string: "focusonyourself://checkin/today"))` or equivalent URL scheme — check existing URL scheme setup or add one.

---

## Acceptance Criteria

- [ ] Placing the CheckInWidget in the widget gallery shows it under FocusOnYourself with display name "Check In"
- [ ] In the unlogged state, 5 mood buttons (Rough/Low/Okay/Good/Great with emoji images) are visible and tappable
- [ ] Tapping a mood button logs the check-in without opening the app; the widget transitions to the confirmed state showing the logged mood and updated streak count
- [ ] The widget shimmer (`invalidatableContent`) fires on the confirmation area between tap and reload
- [ ] In the confirmed state, tapping the widget opens the app to today's check-in detail screen
- [ ] After midnight, the widget resets to the unlogged state for the new day
- [ ] After 8pm with no check-in, the streak icon visually dims (at-risk state) without sending a push notification
- [ ] When the main app is next foregrounded after a widget check-in, the check-in appears in the History screen and the streak count is correct
- [ ] If the user hasn't completed onboarding and taps the widget, the app opens to the onboarding flow
- [ ] The widget renders correctly in both light and dark mode
- [ ] The existing MoodWidget (small, read-only) is unaffected and continues to function

---

## Status

| Phase | Status |
|-------|--------|
| Discovery research | ✅ Complete |
| Feature selected | ✅ Instant Mood Widget |
| Deep-dive research | ✅ Complete |
| User Q&A | ✅ Complete (9 questions resolved) |
| Specification | ✅ Draft |
| Design mockups | ✅ 3 options in Pencil |
| Design approved | ✅ Option C — Warm Greeting |
| Implementation | ⏳ Not started |
