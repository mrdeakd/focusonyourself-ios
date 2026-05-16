## ADDED Requirements

### Requirement: Correlation computation
The system SHALL compute Pearson correlation coefficient between each factor and mood score using only check-ins where `factors != nil`. For the binary `exercised` factor, the system SHALL encode `true` as `1.0` and `false` as `0.0` and apply the same Pearson formula (point-biserial equivalence). The system SHALL rank factors by absolute correlation value (`|r|`) to determine which factor most strongly predicts mood.

#### Scenario: Correlation computed for continuous factor
- **WHEN** `InsightsViewModel` loads with 15+ check-ins containing sleep quality values
- **THEN** a Pearson r value for sleep quality vs mood is computed and available

#### Scenario: Correlation computed for binary factor
- **WHEN** `InsightsViewModel` loads with 15+ check-ins containing exercise data
- **THEN** a point-biserial correlation (via Pearson with 0/1 encoding) for exercise vs mood is computed

#### Scenario: Factors ranked by strength
- **WHEN** all four factor correlations are computed
- **THEN** they are sorted by `|r|` descending so the most impactful factor is first

---

### Requirement: Minimum data gate
The system SHALL NOT display correlation insights until at least 10 check-ins with non-nil `factors` exist. Below this threshold, the system SHALL show an empty-state message in place of the insights section.

#### Scenario: Empty state shown below threshold
- **WHEN** fewer than 10 check-ins with factor data exist
- **THEN** the Insights screen shows "Keep logging to see what affects your mood." in place of the correlation section

#### Scenario: Insights section shown at threshold
- **WHEN** exactly 10 or more check-ins with factor data exist
- **THEN** the correlation ranking section is visible on the Insights screen

---

### Requirement: Top mood booster summary card
The system SHALL display a summary card above the correlation ranking chart showing the single factor with the highest `|r|` value. The card SHALL show the factor name and its direction (positive or negative correlation with mood) as a plain-English sentence (e.g., "Your top mood booster: Exercise ↑").

#### Scenario: Top booster identified and shown
- **WHEN** the insights section is visible and correlations have been computed
- **THEN** a summary card names the highest-|r| factor and its direction

#### Scenario: Top booster reflects direction correctly
- **WHEN** the highest-|r| factor has a negative correlation (e.g., high stress → low mood)
- **THEN** the summary card shows the factor with a "↓ mood" indicator rather than a booster framing

---

### Requirement: Correlation ranking chart
The system SHALL display a horizontal bar chart on the Insights screen ranking all visible factors by correlation strength. Each bar SHALL extend left (negative correlation, navy) or right (positive correlation, orange) from a centre axis at zero. Bars SHALL be labelled with the factor name. The chart SHALL appear as the first section in the Insights screen scroll view, above the existing mood charts.

#### Scenario: Chart shows all visible factors
- **WHEN** the correlation section is displayed
- **THEN** one bar is shown per factor that is enabled in Settings

#### Scenario: Positive correlation shown in orange
- **WHEN** a factor has a positive Pearson r
- **THEN** its bar extends rightward and is filled with the orange accent colour

#### Scenario: Negative correlation shown in navy
- **WHEN** a factor has a negative Pearson r (e.g., stress correlates with lower mood)
- **THEN** its bar extends leftward and is filled with the navy colour

---

### Requirement: Per-factor detail view
The system SHALL provide a tappable drill-down per factor. For continuous factors (sleep, stress, social), the detail SHALL show average mood grouped by low (1–2), medium (3), and high (4–5) factor values as a bar comparison. For the binary exercise factor, the detail SHALL show average mood on exercised days vs non-exercised days as a two-bar comparison. Each group SHALL display the entry count used in its average.

#### Scenario: Continuous factor detail — three groups
- **WHEN** the user taps on the Sleep Quality bar in the ranking chart
- **THEN** a detail view shows average mood for low sleep (1–2), medium (3), and high sleep (4–5) entries

#### Scenario: Binary factor detail — two groups
- **WHEN** the user taps on the Exercise bar in the ranking chart
- **THEN** a detail view shows average mood for exercised days and non-exercised days

#### Scenario: Entry count shown per group
- **WHEN** the detail view is displayed
- **THEN** each bar or group label includes the number of check-ins contributing to that average

#### Scenario: Insufficient data per group
- **WHEN** a group has fewer than 3 entries
- **THEN** that group is shown with a "Not enough data" label rather than an average bar
