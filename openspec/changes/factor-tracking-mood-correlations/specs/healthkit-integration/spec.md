## ADDED Requirements

### Requirement: HKStateOfMind write on check-in
The system SHALL write an `HKStateOfMind` sample to HealthKit on every successful check-in on iOS 17 and later. The write SHALL be fire-and-forget — it SHALL NOT block the check-in flow and SHALL NOT surface errors to the user. The write SHALL occur in a detached async Task after the check-in has been persisted locally.

#### Scenario: Mood written to Health app after check-in
- **WHEN** the user completes a check-in on an iOS 17+ device with HealthKit authorised
- **THEN** an HKStateOfMind sample appears in the Health app under Mental Wellbeing

#### Scenario: Write failure is silent
- **WHEN** HealthKit write fails (e.g., permission revoked, device storage full)
- **THEN** no error is shown to the user and the check-in remains saved locally

#### Scenario: Write does not delay check-in completion
- **WHEN** the user taps "Complete Check-In"
- **THEN** the UI transitions immediately; HealthKit write happens asynchronously without blocking

---

### Requirement: Valence and association mapping
The system SHALL map the app's mood scale to `HKStateOfMind` valence using the formula `(mood.rawValue - 3) / 2.0`, producing values in the range `[-1.0, 1.0]`. When `factors.exercised == true`, the system SHALL include `.exercise` in the `HKStateOfMind` associations array.

#### Scenario: Mood 1 maps to valence -1.0
- **WHEN** the user logs mood level 1 (lowest)
- **THEN** the HKStateOfMind sample has valence `-1.0`

#### Scenario: Mood 3 maps to valence 0.0
- **WHEN** the user logs mood level 3 (middle)
- **THEN** the HKStateOfMind sample has valence `0.0`

#### Scenario: Mood 5 maps to valence 1.0
- **WHEN** the user logs mood level 5 (highest)
- **THEN** the HKStateOfMind sample has valence `1.0`

#### Scenario: Exercise association included when exercised
- **WHEN** the user logs `exercised = true` in factor data
- **THEN** the HKStateOfMind sample includes the `.exercise` association

#### Scenario: No associations when exercise not logged
- **WHEN** `factors` is nil or `exercised == false`
- **THEN** the HKStateOfMind sample is written with an empty associations array

---

### Requirement: One-time HealthKit authorisation
The system SHALL request HealthKit write authorisation (`HKStateOfMind`) exactly once — on the first check-in attempt after install — using `HKHealthStore.requestAuthorization`. The system SHALL NOT present the authorisation prompt during onboarding. Subsequent check-ins SHALL proceed without re-requesting authorisation.

#### Scenario: Auth prompt on first check-in
- **WHEN** the user completes their first check-in and HealthKit has not yet been authorised
- **THEN** the system presents the iOS HealthKit authorisation sheet

#### Scenario: No prompt on subsequent check-ins
- **WHEN** HealthKit authorisation has already been granted or denied
- **THEN** no authorisation sheet is shown on subsequent check-ins

#### Scenario: Auth not requested during onboarding
- **WHEN** the user steps through the onboarding flow
- **THEN** no HealthKit authorisation prompt is displayed

---

### Requirement: iOS version guard
The system SHALL compile and run on iOS 16 without referencing HealthKit APIs. All `HealthKitService` methods SHALL be annotated `@available(iOS 17, *)`. Call sites in `HomeViewModel` SHALL wrap HealthKit calls in `if #available(iOS 17, *)` guards.

#### Scenario: No crash on iOS 16
- **WHEN** the app runs on an iOS 16 device
- **THEN** check-in completes normally with no HealthKit call and no crash

#### Scenario: No crash when HealthKit unavailable
- **WHEN** `HKHealthStore.isHealthDataAvailable()` returns false (e.g., iPads without HealthKit)
- **THEN** the write is skipped silently and the check-in completes normally
