## Why

Users log their mood every day but have no way to understand why it changes — the data accumulates without producing insight. Adding daily context factors (sleep, stress, exercise, social) alongside mood and surfacing statistical correlations closes this gap, turning the app from a logging tool into a behavioural intelligence companion. This is the #1 pain point in peer-reviewed mood-app research and the feature that Bearable, Daylio, and Oura all expanded in 2024–2025.

## What Changes

- New `CheckInFactors` Codable struct added to the data model as an optional field on `CheckIn` (backward-compatible — legacy records decode with `factors: nil`)
- Check-in flow extended with a **Step 2 Card** pattern: after "Complete Check-In", the mood success card appears followed by a "One more thing…" factor card with 4 sliders and Save/Skip buttons
- Settings screen gets 4 factor visibility toggles (all on by default)
- Insights screen gets a new "What affects your mood?" section with a correlation ranking chart and per-factor detail view
- New `HealthKitService` singleton writes an `HKStateOfMind` sample to Apple Health on every check-in (iOS 17+ only, write-only, one-time auth prompt)
- Existing mood reminder notification copy updated to "Log your mood & today's context"

## Capabilities

### New Capabilities

- `factor-check-in`: Factor logging UI (Step 2 Card) in the home check-in flow, `CheckInFactors` model, `ProfileService` changes, and Settings toggles for factor visibility
- `factor-insights`: Pearson correlation computation in `InsightsViewModel`, `FactorCorrelationRankingSection` and `FactorDetailSection` components on the Insights screen, 10-entry minimum data gate, empty state
- `healthkit-integration`: `HealthKitService` writing `HKStateOfMind` samples to Apple Health on check-in, HealthKit entitlement setup, one-time authorisation flow

### Modified Capabilities

(none — no existing specs)

## Impact

**Models:** `CheckIn.swift` — add `var factors: CheckInFactors?`; new `CheckInFactors.swift`

**Services:** `ProfileService` + `ProfileServiceProtocol` — add `factors` param with default `nil`; new `HealthKitService.swift` registered in `Container+App.swift`

**Home feature:** `HomeViewModel.swift` — 4 factor state vars, expanded/collapsed state, updated `completeCheckIn`; new `FactorSlidersView.swift` in `Features/Home/Components/`; `MoodPickerView.swift` — wire Step 2 Card flow

**Insights feature:** `InsightsViewModel.swift` — `factorCorrelations()` and `topMoodBooster()` methods; new `FactorCorrelationRankingSection.swift` and `FactorDetailSection.swift` in `Features/Insights/Components/`; `InsightsScreen.swift` — add new section at top of scroll

**Settings feature:** `SettingsViewModel.swift` + `SettingsScreen.swift` — 4 factor visibility toggles persisted to `UserDefaultsService`

**Project config:** `Info.plist` — `NSHealthUpdateUsageDescription`; Xcode entitlements — `com.apple.developer.healthkit`; `Container+App.swift` — register `HealthKitService`

**Notifications:** `NotificationService` — update reminder body copy only

**Widget:** No changes — `WidgetDataProvider` ignores unknown JSON keys by default
