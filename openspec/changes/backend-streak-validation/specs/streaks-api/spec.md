## ADDED Requirements

### Requirement: GET /api/streaks/me returns server-computed streak stats
The backend SHALL expose `GET /api/streaks/me` behind `requireAuth`, returning a JSON object `{ currentStreak: Int, longestStreak: Int, streakStartDate: ISO8601?, lastCheckInDate: ISO8601? }` computed from the authenticated user's existing `CheckIn` rows. The computation SHALL use the same algorithm as the iOS `StreakCalculator` so server and client produce identical results for identical inputs.

#### Scenario: User with no check-ins
- **WHEN** an authenticated user with zero `CheckIn` rows GETs `/api/streaks/me`
- **THEN** the response is HTTP 200 with `{ currentStreak: 0, longestStreak: 0, streakStartDate: null, lastCheckInDate: null }`

#### Scenario: User with a three-day streak ending today
- **WHEN** an authenticated user has check-ins on `today`, `today-1`, `today-2` (in their timezone) and GETs `/api/streaks/me?tz=<their tz>`
- **THEN** the response has `currentStreak: 3`, `longestStreak >= 3`, and `streakStartDate` matching `today-2`

#### Scenario: User with broken streak
- **WHEN** an authenticated user has check-ins on `today-5`, `today-3`, `today-2`, `today-1`, `today`
- **THEN** the response has `currentStreak: 4` and `longestStreak: 4`

#### Scenario: Unauthenticated request is rejected
- **WHEN** a client GETs `/api/streaks/me` without a valid bearer token
- **THEN** the response is HTTP 401

### Requirement: tz query parameter resolves "today"
The endpoint SHALL accept a `tz` query parameter holding an IANA timezone name. The backend SHALL use this timezone to compute the user's "today" string in `YYYY-MM-DD` form, which anchors the `currentStreak` walk-back. If `tz` is missing, empty, or not a valid IANA name, the backend SHALL default to `UTC` without returning an error.

#### Scenario: Valid timezone is honoured
- **WHEN** a user in Los Angeles GETs `/api/streaks/me?tz=America/Los_Angeles` at 11:30pm PST and has checked in earlier that PST day
- **THEN** the response reflects that PST day as the streak anchor (not the UTC day, which would already be tomorrow)

#### Scenario: Missing tz defaults to UTC
- **WHEN** a client GETs `/api/streaks/me` with no `tz`
- **THEN** the backend computes "today" in UTC and returns a response

#### Scenario: Invalid tz falls back to UTC
- **WHEN** a client GETs `/api/streaks/me?tz=Not/A_Real_Zone`
- **THEN** the backend computes "today" in UTC and returns HTTP 200 (does NOT return 400)

### Requirement: Algorithm matches iOS StreakCalculator
The backend SHALL implement streak computation such that for any identical set of `CheckIn.dateString` values and identical "today" anchor, it produces the same `(current, longest, startDate)` as iOS `StreakCalculator.compute(checkIns:)` + `startDate(checkIns:)`.

#### Scenario: Day-off-then-today matches iOS rule
- **WHEN** check-ins are on `today-2` and `today` (gap on `today-1`)
- **THEN** the backend returns `currentStreak: 1` — matching `StreakCalculator`'s "if today is missing, start from yesterday" behaviour applied to "today" being present but the previous day missing

#### Scenario: No today, yesterday present
- **WHEN** check-ins are on `today-1` only
- **THEN** the backend returns `currentStreak: 1` (the iOS rule starts from yesterday when today is missing)

### Requirement: lastCheckInDate is the maximum dateString
The `lastCheckInDate` field SHALL be the maximum `dateString` across the user's check-ins, formatted as ISO8601 by appending `T00:00:00Z` to the date-only string, or `null` when the user has zero check-ins.

#### Scenario: Multiple check-ins
- **WHEN** a user has check-ins on `today-5` and `today-2`
- **THEN** `lastCheckInDate` is `today-2T00:00:00Z`

#### Scenario: Empty history
- **WHEN** a user has no check-ins
- **THEN** `lastCheckInDate` is `null`
