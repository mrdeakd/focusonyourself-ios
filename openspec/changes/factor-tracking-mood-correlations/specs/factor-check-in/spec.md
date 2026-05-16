## ADDED Requirements

### Requirement: CheckInFactors model
The system SHALL store an optional `CheckInFactors` struct alongside each `CheckIn`. The struct SHALL contain: `sleepQuality: Int` (1–5), `stressLevel: Int` (1–5), `exercised: Bool`, `socialQuality: Int` (1–5). The `factors` field on `CheckIn` SHALL be optional (`CheckInFactors?`) so that legacy check-ins without factor data decode without error.

#### Scenario: New check-in with factors saved
- **WHEN** the user taps Save on the factor card with all sliders set
- **THEN** the resulting `CheckIn` record has a non-nil `factors` value matching the slider values

#### Scenario: Legacy check-in decoded
- **WHEN** a `CheckIn` JSON record without a `"factors"` key is decoded
- **THEN** the record decodes successfully with `factors == nil` and no data is lost

#### Scenario: Check-in skipped factor entry
- **WHEN** the user taps Skip on the factor card
- **THEN** the `CheckIn` is saved with `factors == nil`

---

### Requirement: Step 2 Card flow
After a successful mood check-in, the system SHALL transition to a factor entry state in which a green success card ("Mood logged ✓") is shown above a "One more thing…" factor card. The factor card SHALL present Save and Skip buttons. The primary check-in (mood + notes) SHALL complete and persist before the factor card is shown — factor entry is always a subsequent optional step.

#### Scenario: Factor card appears after check-in
- **WHEN** the user taps "Complete Check-In" with a mood selected
- **THEN** the mood is persisted and the factor entry card is shown without navigation push

#### Scenario: Save completes the flow
- **WHEN** the user taps Save on the factor card
- **THEN** factors are attached to the check-in and the view transitions to the checked-in state

#### Scenario: Skip completes the flow
- **WHEN** the user taps Skip on the factor card
- **THEN** the check-in is left with `factors == nil` and the view transitions to the checked-in state

#### Scenario: Factor card never blocks mood logging
- **WHEN** the check-in is submitted
- **THEN** the mood record is written to persistent storage before the factor card is displayed

---

### Requirement: Factor sliders and controls
The factor card SHALL present: a 1–5 continuous slider for Sleep Quality, a 1–5 continuous slider for Stress Level, a Yes/No chip toggle for Exercise, and a 1–5 continuous slider for Social Quality. Each slider SHALL display its current value (e.g., "4 / 5") adjacent to its label. Sliders SHALL default to 3 (mid-point); the Exercise toggle SHALL default to No.

#### Scenario: Slider value displayed
- **WHEN** the user moves the Sleep Quality slider to position 4
- **THEN** the label reads "4 / 5" and the slider thumb is at the corresponding position

#### Scenario: Exercise toggle selection
- **WHEN** the user taps the "Yes" chip for Exercise
- **THEN** the Yes chip is highlighted (orange) and No is deselected

#### Scenario: Sliders default to mid-point
- **WHEN** the factor card appears for the first time
- **THEN** all sliders are at position 3 and Exercise is set to No

---

### Requirement: Factor visibility settings
The system SHALL provide four toggles in the Settings screen — one per factor — allowing the user to show or hide individual factors from the check-in card. All four SHALL default to visible. Hidden factors SHALL be excluded from the factor card UI and SHALL contribute `nil` equivalent values in the stored `CheckInFactors` (i.e., if a factor is hidden, its field is set to a sentinel default and excluded from correlation analysis). Factor visibility SHALL be stored in App Group `UserDefaults` (device-local, not iCloud-synced).

#### Scenario: Hiding a factor removes it from check-in
- **WHEN** the user disables the Sleep Quality toggle in Settings
- **THEN** the Sleep Quality slider does not appear on the factor card

#### Scenario: Hidden factor does not affect correlation
- **WHEN** a factor has been hidden for the duration of logging
- **THEN** that factor is excluded from the insights correlation computation

#### Scenario: Visibility persists across launches
- **WHEN** the user hides a factor and restarts the app
- **THEN** the factor remains hidden on the factor card

---

### Requirement: Factor state resets after each check-in
The system SHALL reset all factor slider values and the exercise toggle to their defaults after each completed check-in (Save or Skip). The next day's factor card SHALL start from the default values, not the previous day's.

#### Scenario: State reset after Save
- **WHEN** the user saves factor data and the view transitions to checked-in state
- **THEN** internal factor state in HomeViewModel is reset to defaults

#### Scenario: State reset after Skip
- **WHEN** the user taps Skip and the view transitions to checked-in state
- **THEN** internal factor state in HomeViewModel is reset to defaults
