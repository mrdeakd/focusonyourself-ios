# Factor Tracking & Mood Correlations Specification

**Status:** Draft  
**Created:** 2026-05-15  
**Feature:** Add factor sliders (sleep, stress, exercise, social) to the daily check-in, then surface personalised "what affects your mood" correlation insights on the Insights screen.

---

## Discovery Context

**How this was identified:** Ranked #1 most-cited user pain point in peer-reviewed research and App Store review analysis — "I have data but no idea what to do with it." Bearable, Daylio Scales, and Oura Advisor all launched or expanded this feature in 2024–2025, confirming strong market timing. Cross-referenced as the single feature appearing in all three independent research threads (trending features, user pain points, platform patterns).  
**Complexity estimate:** Medium  
**Impact estimate:** High

---

## Problem Statement

Users log their mood every day but the data is descriptive, not actionable. They can see they felt bad on Tuesday but they can't understand why. They have no way to connect their mood to things they control — how they slept, how stressed they were, whether they exercised, how much social connection they had. The data accumulates without producing insight. This feature closes that gap by letting users record daily context alongside their mood, then showing them statistically which factors move their mood up or down.

---

## Research Findings

### What Similar Apps Do

**Daylio Scales (v1.63+, late 2025):** Added horizontal sliders for sleep, stress, energy, and pain directly to the entry screen, after the mood and activity selection. Optional, bolt-on addition to existing flow. Correlation between scale values and mood presumably feeds the existing Stats section (advanced stats are premium-only). The late arrival of this feature — 9 years after launch — confirms this is a gap, not a solved problem.

**Bearable:** Full-featured factor tracking with a long scrollable check-in divided into sections: mood → symptoms → energy → lifestyle factors → sleep → health measurements. Each lifestyle factor can be binary (did/didn't) or 3-point variable (low/medium/high). The "Impacts" section is the industry benchmark for factor-correlation display — shows average mood with vs. without each factor as a bar comparison after 3+ paired entries. Praised for insight depth; criticised for overwhelming setup friction and long check-in times (10+ min for power users).

**MoodKit (Life Intelligence):** Binary activity tagging (no sliders) with a progressive insight unlock: basic summaries at 3 entries, day-of-week patterns at 7, "Emotional ROI" per activity at 14, long-term trends at 30. The Emotional ROI framing ("Exercise gives you the most mood lift of any activity you log") is the most consumer-friendly insight language in the category. The 14-day cold-start to meaningful insight is a major friction point.

**Finch Plus:** Binary goal-completion tracking (exercised yes/no) with weekly habit-mood correlation report showing which goals predicted better mood. Entirely paywalled.

**Apple Health State of Mind:** The canonical reference for clean factor UX. Two-step flow: (1) valence slider with animated morphing shape, (2) descriptive word-picker and context chips. "Life Factors" tab correlates mood against passively collected Apple Watch data (sleep hours, exercise minutes, mindful minutes, daylight exposure) — no manual factor entry required. Zero-setup, completely free, on-device privacy.

**Oura:** Passive biometric data (HRV, sleep stages, temperature) plus manual Tags. The Advisor feature (AI, Nov 2024+) surfaces correlations like "On days you tagged caffeine after 3pm, your sleep score averaged 68 vs. 79." Timeline overlay shows manual tags on the same visual axis as biometric signals. Hardware-dependent ($299+), but the design principle — passive context whenever possible, manual tagging as supplement — is the right model.

**MindDoc / Moodpath:** Three-times-daily clinical questionnaire (PHQ-9/GAD-7 validated). No factor sliders — the questions themselves capture context. Useful for clinical depth, but the rigid question format and push-notification model lead to fatigue and abandonment.

### UX Patterns & Best Practices

**Pattern 1 — Separate mood from factors (different cognitive modes).** Apple Health State of Mind does this canonically: mood valence on a full dedicated screen, context/factors on a separate subsequent step. Mood rating is introspective; factor recall is factual. Blending them on one screen creates mode-switching friction and degrades both inputs. Confirmed by PMC user research: users appreciated "single-purpose" screens during check-in.

**Pattern 2 — 3–4 factors max in default view.** Hick's Law: choice time increases logarithmically with options. A 2024 health app onboarding case study found >4 simultaneous factor inputs caused users to skip the step entirely. Bearable ships 4 default categories for the same reason. The threshold is clear: default to 4, make others opt-in via Settings.

**Pattern 3 — Sliders for mood valence; quick-tap for factual context.** Sliders communicate fluidity for affect. But for sleep quality and stress level, the research finding is specific: users prefer recognition (tap a label) over recall (drag to a number). However, the user selected sliders (1–5) as the preferred input style, matching Daylio Scales. This is a deliberate product choice: more granular data at slightly higher interaction cost.

**Pattern 4 — Pull from HealthKit where possible.** WWDC24 "Explore Wellbeing APIs in HealthKit" demonstrates correlating State of Mind with passively collected sleep/exercise data. Pre-filling sleep quality from Apple Watch data (where available) removes entry burden for the highest-friction factor.

**Pattern 5 — Progressive disclosure for optional depth.** Make factor logging the opt-in path — never blocking completion — so fast users stay fast and thorough users get depth. The check-in must remain completable with zero factor input.

**Pattern 6 — Immediate visual confirmation with insight hint.** After check-in, show an animated completion state. Once enough data exists (10+ entries), show a one-line insight in the completion confirmation: "You've logged 12 days — your data is building up 📈". This closes the habit loop.

### Anti-Patterns to Avoid

**Anti-Pattern 1 — Multiple stacked sliders visible simultaneously.** A column of 4+ labeled sliders on a single screen is the clinical survey model. It reads as a form, not a conversation. Users in wellness contexts specifically describe this as "impersonal" and abandon it. Mitigation: collapsible section, or two-step card flow.

**Anti-Pattern 2 — Mandatory factor completion.** Any design that blocks "Complete Check-In" until all factors are filled will cause users to skip check-in entirely on busy days. Factors must be 100% optional per entry, with a visible skip affordance. This is non-negotiable: users have more check-ins than factor-logged check-ins early on, and that's fine.

**Anti-Pattern 3 — Asking about sleep first in a morning check-in.** Sleep quality is the hardest judgment right after waking. If the morning is the primary check-in time, sleep should appear last in the factor list, after mood and other factors are logged. Anchoring to a negative factor first skews the whole session.

### Technical Considerations

**Model extension — backward-compatible via optional:** Add `factors: CheckInFactors?` as an optional property on the existing `CheckIn` struct. `JSONDecoder` silently ignores missing keys for optionals — legacy check-ins decode to `factors = nil` with no migration required. This is the single most critical technical constraint: a non-optional property would corrupt all existing user data on upgrade.

**Correlation math — Pearson r:** Standard Pearson correlation for continuous factors (sleep 1-5, stress 1-5, social 1-5) against mood (1-5). For the binary exercise factor, point-biserial correlation (mathematically identical to Pearson with 0/1 encoding). The user-facing insight sentence ("on days you exercise, your mood averages 4.2 vs 2.8") is a group mean comparison — simpler and more readable than a raw correlation coefficient. Use Pearson to rank which factors matter most, then show the group-mean sentence for the top factor.

**Minimum data gate:** Correlation insights should only surface after 10+ check-ins that include factor data. Below this threshold, insights are statistically meaningless and potentially misleading.

**Swift Charts:** Already used in `InsightsScreen`. New components follow the existing pattern: `FactorCorrelationRankingSection.swift` and `FactorDetailSection.swift` in `Features/Insights/Components/`, each under the 75-line function body limit.

**HealthKit State of Mind (iOS 17+):** Write an `HKStateOfMind` sample on each check-in. Maps mood (1-5) to HK valence (-1 to +1) via `(mood - 3) / 2.0`. Requires: `com.apple.developer.healthkit` entitlement, `NSHealthUpdateUsageDescription` in Info.plist, `HKHealthStore` authorization request (once, on first check-in or in onboarding). Write-only — no HealthKit reads required for v1. Guard behind `HKHealthStore.isHealthDataAvailable()` — gracefully no-ops on devices without HealthKit support.

**Widget impact:** `WidgetDataProvider.WidgetCheckIn` is a separate struct. New JSON keys from `CheckInFactors` are unknown to the widget decoder — `JSONDecoder` ignores unknown keys by default. No widget changes needed.

**iCloud KVS payload:** Adding 4 small integers per check-in adds ~40-80 bytes per entry. At 365 check-ins/year that is ~30 KB — well within the 1 MB per-key NSUbiquitousKeyValueStore limit.

---

## User Stories

- As a daily user, I want to quickly log how I slept, my stress level, and whether I exercised alongside my mood, so I can build up data about what affects me.
- As a daily user, I want to be able to skip factor logging on days I'm in a hurry, so the check-in never feels like a burden.
- As a power user, I want to see which factors statistically correlate with my best and worst mood days, so I have something actionable to change.
- As a new user, I want to understand why the sliders are there and what they'll give me eventually, so I'm motivated to log them consistently.
- As a user with an Apple Watch, I want my mood data to appear in Apple Health alongside my sleep and fitness data, so I have one unified wellness picture.
- As a user who doesn't exercise, I want to hide the exercise factor from my check-in, so it doesn't feel irrelevant every day.
- As a user returning after a gap, I want to be able to log factors without feeling penalised for skipping previous days, so my insights rebuild accurately from where I am now.
- As a user with 30+ days of factor data, I want to see my single biggest mood booster surfaced prominently, so I can act on it immediately.
- As a user, I want all factor tracking and insights to be free, so I don't feel like the data I provided is being held back from me.

---

## Functional Requirements

### Must Have (launch blocker)
- [ ] `CheckInFactors` struct (sleepQuality 1-5, stressLevel 1-5, exercised Bool, socialQuality 1-5) stored as optional on `CheckIn`
- [ ] Collapsible "Add today's context" section in `MoodPickerView`, revealed by tapping a toggle row above the "Complete Check-In" button
- [ ] 1–5 visual sliders for sleep, stress, and social quality
- [ ] Yes/No toggle (styled as a chip) for exercise
- [ ] All factors entirely optional — "Complete Check-In" works with zero factors filled
- [ ] Factor state persists for the current session in `HomeViewModel`; resets after check-in completes
- [ ] `InsightsViewModel` computes per-factor Pearson correlation and group-mean average (exercised vs not-exercised, high vs low sleep, etc.)
- [ ] `FactorCorrelationRankingSection` on Insights screen: horizontal bar chart ranking all 4 factors by correlation strength, labelled with direction ("↑ mood" / "↓ mood")
- [ ] `FactorDetailSection`: tappable per-factor drill-down showing average mood with/without (binary) or across ranges (continuous)
- [ ] Minimum data gate: insights section hidden and replaced with empty state message until 10 check-ins with factor data exist
- [ ] Empty state message: "Keep logging to see what affects your mood." (no progress indicator, no counter)
- [ ] All factor tracking and insights fully free — no PRO gate
- [ ] HKStateOfMind write on every check-in (iOS 17+ only, guarded with `HKHealthStore.isHealthDataAvailable()`)
- [ ] One-time HealthKit authorisation request shown on first check-in (not during onboarding)
- [ ] Settings toggles to show/hide each individual factor (default: all 4 visible)

### Should Have
- [ ] Factor section remembers its expanded/collapsed state across sessions (persisted to UserDefaults)
- [ ] Insight section shows "Your top mood booster this week: Exercise" summary card above the correlation chart
- [ ] Notification copy updated to "Log your mood & today's context" (existing notification service, wording change only)
- [ ] HealthKit association chip for `exercised == true` maps to `.exercise` on `HKStateOfMind`

### Could Have
- [ ] Pre-fill sleep slider from HealthKit sleep data (if Apple Watch data is available and permission granted)
- [ ] Animated completion confirmation that hints at insights ("Your data is building up 📈") after 5+ factor check-ins
- [ ] Scatter plot visualisation for continuous factors (sleep quality vs mood over time)

### Won't Have (this version)
- Fully customisable factor list (user-defined factor names) — complexity vs. impact ratio too low for v1
- Intraday factor logging (morning vs. evening separate factor entries) — one-per-day is sufficient for v1
- Factor export to CSV/PDF — defer to a future data export feature
- HealthKit reads (sleep from Watch to pre-fill sliders) — write-only HealthKit in v1 to keep scope contained

---

## Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| Performance | Correlation computation runs on `InsightsViewModel` init; must complete in <50ms for up to 500 check-ins |
| Accessibility | All sliders have VoiceOver labels ("Sleep quality, 3 out of 5"); exercise toggle announces state; charts have accessibility descriptions |
| Offline | Fully offline — all factor data stored locally in UserDefaults/iCloud KVS; HealthKit write retried on next launch if it failed |
| iCloud sync | Factors persist in existing `CheckIn` JSON within `UserProfile` in NSUbiquitousKeyValueStore — no new keys |
| Widget impact | No widget changes needed; `WidgetDataProvider` ignores new JSON keys |
| Privacy | HealthKit write only (no read in v1); `NSHealthUpdateUsageDescription` must state purpose clearly; on-device correlation math; no server-side data |
| Notifications | No new notification types; update existing mood reminder copy only |

---

## Design Requirements

**Affected screens:** HomeScreen (`CheckedInCardView`), InsightsScreen  
**New screens needed:** None  
**Navigation entry point:** Factor logging via "Add context" / "Edit context" button on `CheckedInCardView`; insights via Insights tab (tab 3)

**Placement decisions:**

*Post-check-in card (`CheckedInCardView`):*  
After the user checks in, `CheckedInCardView` shows a divider below the mood summary row and an "Add context" / "Edit context" button. Tapping opens `DailyFactorsSheet` (`.medium` bottom sheet) at any time during the day. If factors are already logged, a brief emoji summary is shown ("💤 4  ·  😮‍💨 2  ·  🏃 Yes  ·  👥 3"). This decouples factor timing from check-in timing — users log context when they reflect on the day, not immediately after checking in.

*Insights screen:*  
`FactorCorrelationRankingSection` as the first section in the ScrollView, above `MoodThisWeekSection`.

**Key design constraints:**
- `Color.foyBackground` — sheet background
- `Color.foyCard` — card and toggle-row container
- `Color.foyBorder` — dividers (height 1)
- `Color.foyNavy` — "Add context" / "Edit context" button text
- `Color.foyForegroundSecondary` — factor summary text + sheet description
- `Color.foyOrange` — slider thumb (via `FactorSlidersView`)
- `Spacing.screenHorizontal` — sheet horizontal padding
- `Spacing.lg` — sheet top padding, section gap
- `Spacing.md` — card row horizontal padding
- `Spacing.sm` — card row vertical padding
- Typography: `.foyHintMedium` (button), `.foyHint` (summary), `.foyCaption` (sheet description)
- Sheet: `.presentationDetents([.medium])` + `.presentationDragIndicator(.hidden)`

**Animation/transition:** Standard sheet presentation. No custom animations.

---

## Resolved Open Questions

| # | Question | Answer | Decision |
|---|----------|--------|----------|
| 1 | Where in the check-in flow should factors appear? | Agent investigation of MoodPickerView structure | Collapsible "Add today's context" disclosure above "Complete Check-In" button — preserves fast-path, zero navigation required |
| 2 | What input style for continuous factors? | Visual sliders (1–5) | Sliders for sleep, stress, social; chip toggle for exercise |
| 3 | Where should correlation insights live? | New section on existing Insights screen | `FactorCorrelationRankingSection` as first section in Insights scroll, above mood charts |
| 4 | Should v1 include logging AND insights or just logging? | Both in v1 | Full feature in one release; insights gated at 10 factor check-ins |
| 5 | HealthKit integration? | Yes — write to HKStateOfMind (iOS 17+) | Write-only, one-time auth on first check-in, gracefully no-ops without HealthKit |
| 6 | Default factor set? | 4 factors with Settings toggles to hide | Sleep quality, stress level, exercise (toggle), social quality — all on by default, each hideable |
| 7 | PRO gating? | Fully free | No paywall on factor logging or insights |
| 8 | Empty state before 10 paired entries? | Simple message only | "Keep logging to see what affects your mood." — no counter, no blurred preview |
| 9 | Notifications? | Update copy only | Change existing mood reminder to "Log your mood & today's context" — no new notification type |

---

## Design Options

Three design variants to be created in Pencil:

| Option | Name | Rationale |
|--------|------|-----------|
| A | Button on CheckedInCardView | "Add context" / "Edit context" button below mood summary; opens `DailyFactorsSheet` at any time |
| B | Slide-Up Sheet (original) | Step 2 immediately after check-in — removed due to wrong timing |
| C | Step 2 Card (original) | Immediate two-step card after check-in — removed due to wrong timing |

**Approved option:** ✅ Option A — Button on CheckedInCardView  
**Rationale for change:** The Step 2 Card (Option C) asked for sleep/stress/social context immediately after check-in, before the user has lived the day. Option A decouples factor timing — users log context when they reflect, not under pressure right after checking in.

---

## Implementation Notes

**New files created:**
- `Models/CheckInFactors.swift` — `Codable, Equatable` struct with 4 fields
- `Features/Home/Components/FactorSlidersView.swift` — slider UI, takes `Bindable` ViewModel
- `Features/Home/Components/DailyFactorsSheet.swift` — bottom sheet (.medium) for entering/editing factors; reuses `FactorSlidersView`
- `Features/Insights/Components/FactorCorrelationRankingSection.swift` — horizontal bar chart
- `Features/Insights/Components/FactorDetailSection.swift` — per-factor drill-down
- `Services/HealthKitService.swift` — write-only HKStateOfMind, registered as singleton

**Files modified:**
- `Models/CheckIn.swift` — `var factors: CheckInFactors?`
- `Services/ProfileService.swift` + `ProfileServiceProtocol` — `todaysFactors: CheckInFactors?`, `factors` param on `recordCheckIn`
- `Features/Home/Components/CheckedInCardView.swift` — added context row with "Add context" / "Edit context" button and factor emoji summary
- `Features/Home/HomeViewModel.swift` — `showingContextSheet`, `todaysFactors`, `hasFactorsToday`, `loadFactorsFromToday()`, `saveContext()`; removed Step 2 Card methods
- `Features/Home/HomeScreen.swift` — removed Step 2 branch; added `DailyFactorsSheet` sheet
- `Features/Insights/InsightsScreen.swift` — `FactorCorrelationRankingSection` at top of scroll
- `Features/Insights/InsightsViewModel.swift` — `factorCorrelations()`, `topMoodBooster()`, correlation math
- `Features/Settings/SettingsScreen.swift` + `SettingsViewModel.swift` — Daily Context section (sheet-based)
- `App/Container+App.swift` — `HealthKitService` registered
- `FocusOnYourself/Info.plist` — `NSHealthUpdateUsageDescription`
- Xcode entitlements — `com.apple.developer.healthkit`

**Files deleted:**
- `Features/Home/Components/FactorCardView.swift` — Step 2 Card (removed)
- `Features/Home/Components/MoodLoggedCardView.swift` — Step 2 success card (removed)

**Critical implementation note:** `CheckInFactors` must be added as `var factors: CheckInFactors?` (optional). A non-optional addition will cause `JSONDecoder` to throw when decoding legacy check-ins, triggering `ProfileService`'s fallback to `UserProfile()` and silently wiping all user history. Verify with a test that decodes a hardcoded legacy `CheckIn` JSON string and asserts `factors == nil`.

**Correlation math placement:** Add `factorCorrelations() -> [FactorCorrelation]` and `averageMood(withFactor:) -> Double?` to `InsightsViewModel`. If these methods push the file past 400 lines, extract to `FactorInsightsViewModel`.

**Widget sync:** No changes to `WidgetDataProvider.WidgetCheckIn` — `JSONDecoder` ignores unknown keys by default.

---

## Acceptance Criteria

- [ ] User can complete a check-in with zero factor input — no regression to existing flow
- [ ] After check-in, `CheckedInCardView` shows "Add context" button below mood summary
- [ ] Tapping "Add context" opens `DailyFactorsSheet` with default slider values (3/3/No/3)
- [ ] Sleep, stress, and social quality sliders accept values 1–5 with orange thumb
- [ ] Exercise toggle changes between "Yes" and "No" states
- [ ] Tapping Save on the sheet persists factors and updates the button to "Edit context" with emoji summary
- [ ] Tapping "Edit context" reopens the sheet pre-filled with existing values
- [ ] Factor values are persisted on the `CheckIn` model and appear in History data
- [ ] Factors from previous check-ins decode correctly (no data loss for legacy records)
- [ ] Insights screen shows `FactorCorrelationRankingSection` when 10+ factor check-ins exist
- [ ] Insights section shows "Keep logging to see what affects your mood." when fewer than 10 factor check-ins exist
- [ ] Correlation ranking chart shows all 4 factors ordered by |r| with direction arrows
- [ ] Tapping a factor opens the detail view with average mood comparison
- [ ] "Your top mood booster" summary card shows the highest-correlation factor
- [ ] Settings screen shows 4 factor visibility toggles; hiding a factor removes it from the check-in section
- [ ] On iOS 17+ devices, completing a check-in writes an `HKStateOfMind` sample to Apple Health
- [ ] On iOS 16 or devices without HealthKit, no crash or error — graceful no-op
- [ ] HealthKit authorisation prompt appears on first check-in, not during onboarding
- [ ] Existing mood reminder notification displays updated copy "Log your mood & today's context"
- [ ] All features are available without PRO subscription
- [ ] Build passes with no SwiftLint errors

---

## Status

| Phase | Status |
|-------|--------|
| Discovery research | ✅ Complete |
| Feature selected | ✅ Factor Tracking & Mood Correlations |
| Deep-dive research | ✅ Complete |
| User Q&A | ✅ Complete (9 questions resolved) |
| Specification | ✅ Draft |
| Design mockups | ✅ 3 options in Pencil |
| Design approved | ✅ Option C — Step 2 Card |
| Implementation | ⏳ Not started |
