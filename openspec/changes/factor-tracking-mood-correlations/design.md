## Context

The app uses MVVM + Factory DI on iOS 17+. All user data is stored as JSON-encoded `Codable` structs in `NSUbiquitousKeyValueStore` (iCloud KVS) under a single `userProfile` key via `UserDefaultsService`. The root model is `UserProfile` which contains `[CheckIn]`. `ProfileService` is the sole owner of read/write operations. There are no CoreData or Firebase dependencies.

`CheckIn` currently stores: `dateString`, `mood` (enum), `feelingsDescription` (optional String). It is persisted and synced across devices. Existing check-ins on disk and in iCloud have no factor data — any model change must decode cleanly without those keys.

The check-in flow lives on `HomeScreen`: `HomeViewModel` owns `selectedMood`, `feelingsDescription`, and calls `profileService.recordCheckIn`. The UI shows either a `MoodPickerView` (pre-check-in) or a `CheckedInCardView` (post-check-in) based on `homeViewModel.hasCheckedInToday`.

Two widgets (`MoodWidget`, `StreakWidget`) read from a shared App Group via `WidgetDataProvider`, which has its own `WidgetCheckIn` struct that mirrors `CheckIn`. The widget target cannot import the main target.

## Goals / Non-Goals

**Goals:**
- Extend `CheckIn` with optional factor data — zero data loss for existing users on upgrade
- Add Step 2 Card UX after mood logging (approved design: Option C)
- Compute and display per-factor mood correlations on Insights screen
- Write each check-in to Apple Health as `HKStateOfMind` (iOS 17+, write-only)
- Expose per-factor visibility toggles in Settings

**Non-Goals:**
- Reading HealthKit data to pre-fill sliders (write-only in this version)
- Customisable factor names/types (fixed set: sleep, stress, exercise, social)
- Intraday factor logging (one set of factors per day, matching one check-in per day)
- CSV/PDF data export
- Correlation sharing or social features

## Decisions

### 1. `CheckInFactors` as an optional struct on `CheckIn`

**Decision:** Add `var factors: CheckInFactors?` — a single optional nested struct, not four separate optional fields on `CheckIn`.

**Rationale:** Grouping all factor fields into one optional struct means `JSONDecoder` either decodes the entire `factors` key (all fields present) or leaves it `nil` (key absent). It avoids a messy partially-populated state where some factor fields exist and others don't. Adding four separate optional `Int?` fields would make correlation filtering more complex ("only include entries where all four factors are present") versus a single `factors != nil` nil-check.

**Backward compatibility:** `JSONDecoder` does not throw on missing keys for `Optional` properties by default. Legacy check-ins decode with `factors = nil` without any custom `init(from:)` required. The widget's `WidgetCheckIn` struct is unaffected — unknown JSON keys are silently ignored.

**Alternative considered:** A version-tagged migration approach (store a schema version int in `UserProfile`, run migration on load). Rejected: overkill for a purely additive optional field.

---

### 2. Step 2 Card flow (not inline expansion or bottom sheet)

**Decision:** After `completeCheckIn()` succeeds, `HomeViewModel` transitions to a new `.factorEntry` state. `HomeScreen` renders a success card ("Mood logged ✓") followed by `FactorSlidersView` card. "Save" calls a new `saveFactors()` method; "Skip" skips directly.

**Rationale:** Keeps the primary check-in action (mood + notes) a single focused interaction. The factor card appearing afterward never blocks the fast path — "Skip" is always available. This pattern also avoids adding visual weight to `MoodPickerView`, which is already at a comfortable length. The bottom sheet alternative (Option B) requires presenting a sheet over the existing card, which complicates dismiss handling and conflicts with the keyboard-dismissal pattern on the text editor.

**State machine in HomeViewModel:**
```
.idle → .moodEntry → .factorEntry → .checkedIn
```
`.moodEntry` is the existing state (MoodPickerView visible). `.factorEntry` is new. `.checkedIn` is the existing CheckedInCardView state.

---

### 3. Pearson correlation + group-mean sentences

**Decision:** Use Pearson r to rank which factors matter most, then surface insights as plain-English group-mean comparisons ("On days you exercise, your average mood is 4.1 vs 2.7").

**Rationale:** Pearson r on 1-5 ordinal data is the standard consumer-app approach — it requires no external library, is fast on small datasets (<500 check-ins), and gives a single rankable number per factor. Point-biserial correlation (exercise Bool vs mood) is mathematically equivalent to Pearson with 0/1 encoding, so one function handles all four factors. The group-mean sentence is more legible than a raw coefficient and directly actionable.

**Minimum data gate:** Show the insights section only when `checkInsWithFactors.count >= 10`. Below this, show: "Keep logging to see what affects your mood." No progress counter.

**Performance:** Correlation is computed in `InsightsViewModel.init` / `onAppear`. On a dataset of 500 check-ins, four Pearson calculations take <1ms. No background threading required.

---

### 4. HealthKit write-only, iOS 17+, graceful no-op

**Decision:** `HealthKitService` wraps all HealthKit calls. It is registered as a singleton in `Container+App`. On `recordCheckIn`, `HomeViewModel` calls `healthKitService.writeStateOfMind(mood:factors:)` asynchronously in a detached `Task` — failures are silently swallowed (not user-visible). The one-time auth request fires on the first check-in attempt, not during onboarding.

**Rationale:** HealthKit failure should never block or degrade the check-in UX. The write is best-effort telemetry to Apple Health. Triggering auth during onboarding would add a third permission prompt (after notification permission) before the user has seen the app's core value — deferring to first check-in is a better permission UX.

**Valence mapping:** `mood (1–5) → HKStateOfMind valence (-1.0 to +1.0)` via `(Double(mood.rawValue) - 3.0) / 2.0`. Exercise maps to `.exercise` association on `HKStateOfMind` when `exercised == true`.

**iOS version guard:** All `HealthKitService` methods are annotated `@available(iOS 17, *)`. `HomeViewModel` wraps the call in `if #available(iOS 17, *)`. No crash on iOS 16 devices.

---

### 5. Factor visibility persisted to UserDefaults (not iCloud KVS)

**Decision:** The four "show/hide factor" settings are stored in `UserDefaultsService` using standard `UserDefaults` (App Group), not `NSUbiquitousKeyValueStore`.

**Rationale:** Factor visibility is a device-level UI preference, not user data. It does not need to sync across devices (a user may want factors visible on iPhone but hidden on iPad). Using the App Group `UserDefaults` also means the setting is available to future widgets without requiring a KVS sync. Four new `UserDefaultsKey` enum cases are added: `.showSleepFactor`, `.showStressFactor`, `.showExerciseFactor`, `.showSocialFactor`.

## Risks / Trade-offs

**[Risk] iCloud KVS data loss on decode failure** → The entire `UserProfile` JSON is stored under one key. If a future `CheckInFactors` field is added as non-optional, decoding would fail and `ProfileService` would fall back to `UserProfile()`, silently erasing history. Mitigation: `CheckInFactors` fields must always be optional or have defaults. Document this constraint in a comment on the struct.

**[Risk] HealthKit App Review scrutiny** → Adding the HealthKit entitlement triggers a longer review process. The `NSHealthUpdateUsageDescription` must clearly state the purpose. Mitigation: Use copy: "FocusOnYourself writes your daily mood to Apple Health so you can view it alongside your other health data."

**[Risk] Correlation misleads with small datasets** → With 10–15 entries, Pearson r can produce a strong-looking correlation from noise. Mitigation: The 10-entry gate is a floor, not a guarantee of statistical significance. Consider adding a confidence indicator ("Based on 10 days") in the insight sentence for datasets under 30 entries.

**[Risk] Step 2 Card is skipped by most users** → If the majority of users tap "Skip" every time, factor data will be sparse and insights will be slow to emerge. Mitigation: The card is framed as "One more thing…" (low commitment) and always shows a Skip button — the goal is habit formation, not forced completion. Engagement can be measured by `factors != nil` rate over time.

**[Trade-off] Pearson on ordinal data** → Strictly, Pearson assumes interval-level data. Mood and factor scales are ordinal (1-5). Spearman rank correlation would be more statistically rigorous. Pearson is used because it is simpler to implement, produces equivalent rankings for this scale, and the difference is not user-visible. The insights are consumer-facing, not clinical.

## Migration Plan

No migration script needed. The change is purely additive:

1. Ship the update. Existing users' `UserProfile` JSON decodes with `factors: nil` on all legacy `CheckIn` records — no data loss, no error.
2. New check-ins from this version onwards will populate `factors` when the user fills in the Step 2 Card and taps Save.
3. The Insights section remains hidden (`factors` count < 10) until enough factor check-ins accumulate naturally.
4. HealthKit entitlement is additive — no existing HealthKit data is touched.

**Rollback:** Remove the `factors` field from `CheckIn` in a subsequent release. Legacy records will decode without it. No reverse migration needed.

## Open Questions

(none — all decisions resolved during spec Q&A and design analysis)
