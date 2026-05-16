## 1. Data Model

- [x] 1.1 Create `Models/CheckInFactors.swift` — `Codable, Equatable` struct with `sleepQuality: Int`, `stressLevel: Int`, `exercised: Bool`, `socialQuality: Int`; add a comment warning that all fields must remain optional or have defaults to prevent KVS decode failures
- [x] 1.2 Add `var factors: CheckInFactors?` to `CheckIn` in `Models/CheckIn.swift` — verify existing `CheckIn` JSON string decodes with `factors == nil` (manual test with hardcoded legacy JSON in a debug print or playground)
- [x] 1.3 Add four `UserDefaultsKey` cases to `UserDefaultsService`: `.showSleepFactor`, `.showStressFactor`, `.showExerciseFactor`, `.showSocialFactor` — all default to `true`

## 2. Profile Service

- [x] 2.1 Add `factors: CheckInFactors? = nil` parameter to `recordCheckIn` in `ProfileServiceProtocol`
- [x] 2.2 Update `ProfileService.recordCheckIn` to accept and store the `factors` parameter on the `CheckIn` being saved
- [x] 2.3 Verify all existing call sites of `recordCheckIn` still compile (default `nil` means no changes needed at call sites)

## 3. HealthKit Integration

- [x] 3.1 Add `com.apple.developer.healthkit` entitlement to the app target in Xcode
- [x] 3.2 Add `NSHealthUpdateUsageDescription` to `FocusOnYourself/Info.plist` — merged into generated plist by Xcode at build time
- [x] 3.3 Create `Services/HealthKitService.swift` — `@MainActor` singleton; `@available(iOS 17, *)` annotation on the class; `requestAuthorization()` method; `writeStateOfMind(mood: Mood, factors: CheckInFactors?)` method implementing valence mapping `(mood.rawValue - 3) / 2.0` and `.fitness` association when `exercised == true`
- [x] 3.4 Register `HealthKitService` as a singleton in `Container+App.swift`; guard the registration with `@available(iOS 17, *)`
- [x] 3.5 Inject `HealthKitService` into `HomeViewModel` via `Container.shared`; call `writeStateOfMind` in a detached `Task` after `recordCheckIn` succeeds; wrap in `if #available(iOS 17, *)` guard

## 4. Factor Check-In UI

- [x] 4.1 Add factor state vars to `HomeViewModel`: `sleepQuality: Int = 3`, `stressLevel: Int = 3`, `exercised: Bool = false`, `socialQuality: Int = 3`; add `isShowingFactorCard: Bool = false`; add `resetFactors()` helper that resets all four to defaults
- [x] 4.2 Update `HomeViewModel.completeCheckIn()` to set `isShowingFactorCard = true` instead of immediately calling `profileService.recordCheckIn`; add `saveFactors()` that calls `recordCheckIn` with current factor state then calls `resetFactors()`; add `skipFactors()` that calls `recordCheckIn` with `factors: nil` then calls `resetFactors()`
- [x] 4.3 Create `Features/Home/Components/FactorSlidersView.swift` — takes `Bindable<HomeViewModel>`; renders Sleep Quality slider (1–5), Stress Level slider (1–5), Exercise Yes/No chips, Social Quality slider (1–5); each slider shows its current value as "X / 5" next to its label; all factors use `Spacing.*` and `CornerRadius.*` tokens; respects factor visibility from `UserDefaultsService`
- [x] 4.4 Update `HomeScreen.swift` to show the Step 2 Card when `viewModel.isShowingFactorCard`: render a green success card ("Mood logged ✓") followed by the "One more thing…" `FactorSlidersView` card with Save and Skip buttons; Save calls `viewModel.saveFactors()`, Skip calls `viewModel.skipFactors()`
- [ ] 4.5 Verify the fast path: complete a check-in without opening the factor card — the flow should work identically to before this change
- [x] 4.6 Run `swiftlint --fix && swiftlint` and fix any violations in new files

## 5. Settings Factor Toggles

- [x] 5.1 Add four bool properties to `SettingsViewModel` for factor visibility, reading from and writing to `UserDefaultsService.getLocalBool/setLocalBool`
- [x] 5.2 Add a "Daily Context" section to `SettingsScreen.swift` with four toggles (Sleep Quality, Stress Level, Exercise, Social Quality) bound to the `SettingsViewModel` properties
- [ ] 5.3 Verify `FactorSlidersView` reads the same `UserDefaultsService` keys and hides rows whose visibility flag is `false`

## 6. Insights — Correlation Engine

- [x] 6.1 Add `factorCheckIns: [CheckIn]` computed property to `InsightsViewModel` that filters `profileService.profile.checkIns` to only those with non-nil `factors`
- [x] 6.2 Implement `pearsonCorrelation(_ xs: [Double], _ ys: [Double]) -> Double?` as a private static method in `InsightsViewModel`
- [x] 6.3 Implement `factorCorrelations() -> [FactorCorrelation]` returning a struct with `factor: String`, `pearsonR: Double`, and `directionLabel: String`; sort by `|pearsonR|` descending; guard against `factorCheckIns.count < 10` returning empty array
- [x] 6.4 Implement `topMoodBooster() -> FactorCorrelation?` returning the first element of `factorCorrelations()` or `nil` when fewer than 10 entries exist
- [x] 6.5 Implement `averageMood(forBinaryFactor keyPath: KeyPath<CheckInFactors, Bool>) -> (with: Double?, without: Double?)` for the exercise binary comparison
- [x] 6.6 Implement `averageMoodByRange(forFactor keyPath: KeyPath<CheckInFactors, Int>) -> (low: FactorRangeGroup, mid: FactorRangeGroup, high: FactorRangeGroup)` grouping 1–2 as low, 3 as mid, 4–5 as high; include entry counts per group

## 7. Insights — UI Components

- [x] 7.1 Create `Features/Insights/Components/FactorCorrelationRankingSection.swift` — horizontal bar chart using Swift Charts; one `BarMark` per factor; bars extend right (orange) for positive r and left (navy) for negative r; chart x-axis domain `[-1, 1]`; factor name labels on y-axis
- [x] 7.2 Create `Features/Insights/Components/FactorDetailSection.swift` — shows the top booster summary card above the ranking chart; tapping a bar in the ranking chart expands an inline detail view showing the group-mean comparison for that factor
- [x] 7.3 Empty state in `FactorCorrelationRankingSection`: when `factorCorrelations()` is empty, renders "Keep logging to see what affects your mood." in place of the chart
- [x] 7.4 Insert `FactorCorrelationRankingSection` as the first section inside the `ScrollView` in `InsightsScreen.swift`, above `MoodThisWeekSection`
- [x] 7.5 Run `swiftlint --fix && swiftlint` and fix any violations in new insight files

## 8. Notification Copy Update

- [x] 8.1 Find the mood reminder notification body string in `NotificationService.swift` and update it to "Log your mood & today's context."

## 9. Build & Verification

- [x] 9.1 Build for iOS Simulator — BUILD SUCCEEDED
- [ ] 9.2 Manually verify the check-in flow: complete a check-in → factor card appears → Save → checked-in state shown
- [ ] 9.3 Manually verify the skip path: complete a check-in → factor card appears → Skip → checked-in state shown, `factors == nil`
- [ ] 9.4 Manually verify legacy decode safety: add a debug print in `ProfileService.init` logging the count of check-ins with nil factors — confirm existing records load correctly
- [ ] 9.5 Manually verify the Insights screen shows the empty state before 10 factor check-ins and the correlation section after
- [ ] 9.6 Manually verify Settings toggles hide/show factors on the check-in card
- [ ] 9.7 On an iOS 17+ device or simulator, verify mood data appears in the Health app after a check-in
