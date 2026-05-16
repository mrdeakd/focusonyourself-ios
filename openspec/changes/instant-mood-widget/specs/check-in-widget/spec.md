## ADDED Requirements

### Requirement: Widget mood selection
The system SHALL provide a `.systemMedium` home screen widget (`CheckInWidget`, kind `"CheckInWidget"`) that displays five interactive mood buttons (Rough, Low, Okay, Good, Great) allowing the user to log today's check-in with a single tap, without launching the app.

#### Scenario: User taps a mood button while not yet checked in today
- **WHEN** the user taps any of the five mood buttons on the unlogged widget
- **THEN** the check-in is recorded for today with the selected mood
- **THEN** the app is NOT launched
- **THEN** the widget transitions to the confirmed state

#### Scenario: Widget appears in the unlogged state
- **WHEN** the user views the widget and has not checked in today
- **THEN** all five mood buttons are visible and tappable
- **THEN** the current streak count is displayed as a "🔥 N" indicator

### Requirement: In-widget confirmation with shimmer feedback
The system SHALL provide immediate visual feedback on tap using `.invalidatableContent()` on the header and confirmation area, followed by a transition to the confirmed state after the intent completes.

#### Scenario: Shimmer fires on tap
- **WHEN** the user taps a mood button
- **THEN** the header and confirmation area shimmer immediately (before the intent round-trip completes)
- **THEN** the widget re-renders with the confirmed state once the intent finishes

### Requirement: Confirmed state after logging
The system SHALL display a confirmed state after a successful check-in showing the logged mood emoji, mood name, and "Logged ✓".

#### Scenario: Widget shows confirmed state after logging
- **WHEN** the user has checked in today (via widget or app)
- **THEN** the mood buttons are replaced by the logged mood emoji and name
- **THEN** "Logged ✓" is displayed below the mood name
- **THEN** the streak count reflects today's completed check-in

### Requirement: Streak display
The system SHALL display the current check-in streak count as a "🔥 N" indicator in both the unlogged and confirmed states.

#### Scenario: Streak is visible in both states
- **WHEN** the user views the widget in either state
- **THEN** the streak count is visible as a flame icon with the number

#### Scenario: Streak updates after logging
- **WHEN** the user taps a mood button and the widget transitions to confirmed state
- **THEN** the streak counter reflects the incremented value using `.contentTransition(.numericText())`

### Requirement: Midnight daily reset
The system SHALL reset the widget to the unlogged state at the start of each new calendar day.

#### Scenario: Widget resets at midnight
- **WHEN** the calendar day changes to a new date
- **THEN** the widget displays the unlogged state with mood buttons

### Requirement: Widget-logged check-in foreground merge
The system SHALL merge check-ins logged via the widget into the main app's iCloud KVS-backed profile the next time the app is foregrounded, ensuring they appear in History and contribute to streak calculations.

#### Scenario: Widget check-in syncs to iCloud on next foreground
- **WHEN** the user logs a mood via the widget
- **WHEN** the user next opens the app (app becomes active)
- **THEN** the widget-logged check-in appears in the History screen
- **THEN** the streak count in the app matches the widget's streak count

#### Scenario: Widget check-in does not overwrite a more-recent in-app check-in
- **WHEN** a widget check-in exists for today
- **WHEN** the app already has a check-in for today that is newer
- **THEN** the app's check-in is preserved and the widget pending entry is discarded

### Requirement: Onboarding guard
The system SHALL show a "Get Started →" prompt when the user has not completed onboarding, which opens the app to the onboarding flow.

#### Scenario: Unonboarded user views widget
- **WHEN** the user views the widget
- **WHEN** the user's profile has `onboardingCompleted == false`
- **THEN** mood buttons are not shown
- **THEN** a "Get Started →" button is displayed that opens the app

### Requirement: No regression on existing widgets
The system SHALL leave the existing `MoodWidget` (kind `"MoodWidget"`, `.systemSmall`, read-only) and `StreakWidget` completely unchanged.

#### Scenario: Existing MoodWidget continues to function after update
- **WHEN** the app is updated to include the new CheckInWidget
- **THEN** existing MoodWidget placements remain on users' home screens
- **THEN** MoodWidget continues to display today's mood and logged status correctly

### Requirement: Light and dark mode rendering
The system SHALL render the CheckInWidget correctly in both light and dark mode using SwiftUI adaptive colors.

#### Scenario: Widget renders in both modes
- **WHEN** the device is in light or dark mode
- **THEN** the widget content remains legible
- **THEN** mood button backgrounds and text use `Color.secondary`-based adaptive colors
