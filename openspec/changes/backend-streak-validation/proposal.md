## Why

Streaks are a primary retention mechanic in the app — `HomeScreen`'s headline number and `HistoryScreen`'s "Current Streak" / "Longest Streak" stat cards both come from `StreakCalculator` running purely on the device against `profileUseCase.profile.checkIns`. Check-ins are stored in iCloud KVS, which is freely editable from any device signed into the same iCloud account. The device clock can also be manipulated to extend "current streak" artificially. There is no server-authoritative record of a user's streak, which means: (1) leaderboards / social features that compare streaks across users are impossible to add later without rewriting this, (2) referral or milestone rewards cannot be gated on a trustworthy streak number, and (3) cross-device installs cannot fall back on the server to reconstruct streaks if the iCloud cache is empty.

This change moves streak computation to the backend, derived from the existing `CheckIn` rows the server already stores via `CheckinsService`. The iOS app continues to call `streakStats()` and `streakStartDate()` synchronously — the values come from a server-fetched cache held on `CheckInUseCase` and persisted to App Group UserDefaults. The local `StreakCalculator` is deleted: keeping it as an "offline fallback" would let any user defeat the server-authoritative model simply by toggling airplane mode, so the only fallback is the last-known cached server result.

## What Changes

- **Backend: new endpoint** `GET /api/streaks/me?tz=<IANA timezone>` — returns `{ currentStreak: Int, longestStreak: Int, streakStartDate: ISO8601?, lastCheckInDate: ISO8601? }` computed from the authenticated user's `CheckIn` rows. The `tz` query param controls which timezone the server uses to determine "today" for the `currentStreak` calculation; if missing or invalid the server SHALL use UTC.
- **Backend: streak compute helper** `computeStreaks(dateStrings, today)` — pure function operating on `YYYY-MM-DD` strings; timezone only matters for resolving the "today" anchor
- **iOS: new** wire model `StreakStatsResponse` in `Networking/Models/`
- **iOS: new** `StreaksService` + protocol — thin Service wrapping `GET /api/streaks/me`
- **iOS: new** typed feature error `StreaksError: UserFacingError` in `Domain/Errors/`
- **iOS: modify** `CheckInUseCase` — becomes `@Observable @MainActor final class`, gains `private(set) var serverStreaks: ServerStreakStats?` (new domain model), injects `StreaksService`, adds `func refreshStreaksFromServer() async throws`, persists the cached `ServerStreakStats` to App Group UserDefaults via `UserDefaultsStore`
- **iOS: modify** `CheckInUseCase.streakStats()` and `.streakStartDate()` — return values from `serverStreaks` when present; return `(0, 0)` / `nil` when not
- **iOS: modify** `CheckInUseCase.save(_:)` and `downloadAndReplaceFromServer()` — call `refreshStreaksFromServer()` in a fire-and-forget task after the underlying mutation so the server-derived streak stays current
- **iOS: modify** `HomeViewModel.onAppear` and `HistoryViewModel.onAppear` (or equivalent load entry points) — call `checkInUseCase.refreshStreaksFromServer()` so the headline numbers refresh on screen visits
- **iOS: new** `UserDefaultsKey.serverStreakStats` for the cache
- **iOS: new** `Domain/Models/ServerStreakStats.swift` — plain `Codable` struct mirroring the response
- **iOS: delete** `FocusOnYourself/Domain/Calculators/StreakCalculator.swift` and remove its `private let streakCalculator = StreakCalculator()` declaration from `CheckInUseCase`
- **Widget: modify** `FocusOnYourselfWidgets/WidgetDataProvider.swift` — replace the in-process streak algorithm in `streakStats()` with a decode of the cached `ServerStreakStats` blob from the App Group UserDefaults key `"server-streak-stats"`; add a `WidgetServerStreakStats` mirror struct mirroring the main app's `ServerStreakStats` field-for-field

**Unchanged:**
- `CheckInUseCaseProtocol.streakStats()` and `.streakStartDate()` signatures — still synchronous, still return the same tuple/optional
- All call sites (`HomeViewModel.streakCount`, `HistoryViewModel.streakStats`) — they continue to read synchronously
- `CheckinsService` — `post`, `fetch`, `importAll` signatures unchanged; the backend already has the data it needs
- Widget timeline / entry shapes — `CheckInEntry.streak` and `StreakEntry.currentStreak/longestStreak` keep their types; only the data source inside `WidgetDataProvider` changes

## Capabilities

### New Capabilities

- `streaks-api`: Backend endpoint `GET /api/streaks/me?tz=<IANA timezone>` returning server-authoritative `{ currentStreak, longestStreak, streakStartDate, lastCheckInDate }` computed from the authenticated user's existing `CheckIn` rows

### Modified Capabilities

- `check-in-use-case`: `CheckInUseCase` becomes `@Observable`, holds a cached `ServerStreakStats?` from the backend, refreshes it on check-in mutations and on screen load; `streakStats()` and `streakStartDate()` prefer server values, fall back to local `StreakCalculator`

## Impact

**Backend files modified:**
- `src/routes/streaks.ts` — new route file
- `src/index.ts` — mount streaks router at `/api/streaks`
- `src/services/streakCalculator.ts` — new shared helper

**iOS files modified:**
- `FocusOnYourself/Domain/UseCases/CheckIn/CheckInUseCase.swift` — `@Observable`, server-streak caching, refresh method; remove `streakCalculator` member
- `FocusOnYourself/Domain/UseCases/CheckIn/CheckInUseCaseProtocol.swift` — add `refreshStreaksFromServer() async throws` and `var serverStreaks: ServerStreakStats?`
- `FocusOnYourself/Features/Home/HomeViewModel.swift` — call refresh on appear
- `FocusOnYourself/Features/History/HistoryViewModel.swift` — call refresh on appear
- `FocusOnYourself/Domain/Models/UserDefaultsKey.swift` — add `.serverStreakStats`
- `FocusOnYourself/App/Container+App.swift` — register `streaksService` under `// MARK: - Services`
- `FocusOnYourselfWidgets/WidgetDataProvider.swift` — `streakStats()` decodes the cached `ServerStreakStats` blob from the App Group instead of computing locally; add `WidgetServerStreakStats` mirror struct

**iOS files added:**
- `FocusOnYourself/Domain/Models/ServerStreakStats.swift`
- `FocusOnYourself/Services/Streaks/StreaksServiceProtocol.swift`
- `FocusOnYourself/Services/Streaks/StreaksService.swift`
- `FocusOnYourself/Networking/Models/StreakStatsResponse.swift`
- `FocusOnYourself/Domain/Errors/StreaksError.swift`

**iOS files deleted:**
- `FocusOnYourself/Domain/Calculators/StreakCalculator.swift` — replaced by the server endpoint; keeping it would let any user defeat server authority by going offline

**No changes to:**
- `CheckIn.swift`, `BackendCheckIn.swift`, `CheckinsService.swift`
- `HistoryScreen.swift`, `HomeScreen.swift` (they keep reading `viewModel.streakStats` / `viewModel.streakCount`)
- Widget entry types and views (`StreakEntry`, `CheckInEntry`, layout code) — only the data-source line inside `WidgetDataProvider` changes
