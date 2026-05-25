## MODIFIED Requirements

### Requirement: streakStats reads only from the server cache
`CheckInUseCase.streakStats()` SHALL return `(serverStreaks?.currentStreak ?? 0, serverStreaks?.longestStreak ?? 0)`. The method SHALL remain synchronous, SHALL retain its `(current: Int, longest: Int)` return type, and SHALL NOT compute from local check-in data. There is no client-side streak algorithm.

#### Scenario: Server cache available
- **WHEN** `serverStreaks` is set to `ServerStreakStats(currentStreak: 7, longestStreak: 14, ...)`
- **THEN** `streakStats()` returns `(current: 7, longest: 14)`

#### Scenario: No server cache
- **WHEN** `serverStreaks` is `nil` regardless of whether `profileUseCase.profile.checkIns` is empty or populated
- **THEN** `streakStats()` returns `(current: 0, longest: 0)`

### Requirement: streakStartDate reads only from the server cache
`CheckInUseCase.streakStartDate()` SHALL return `serverStreaks?.streakStartDate`. The method SHALL NOT compute from local check-in data.

#### Scenario: Server cache available
- **WHEN** `serverStreaks?.streakStartDate` is set
- **THEN** `streakStartDate()` returns that date

#### Scenario: No server cache
- **WHEN** `serverStreaks` is `nil`
- **THEN** `streakStartDate()` returns `nil`

### Requirement: save triggers a fire-and-forget streak refresh
After persisting a check-in mutation through `profileUseCase.updateCheckIns(...)` and dispatching `Task { try? await checkinsService.post(checkIn) }`, `CheckInUseCase.save(_:)` SHALL cancel any in-flight streak refresh and start a new fire-and-forget `Task` invoking `refreshStreaksFromServer()`. A failure of the refresh SHALL NOT propagate to the caller.

#### Scenario: New check-in triggers refresh
- **WHEN** `record(mood:feelingsDescription:factors:)` is called on a logged-in user
- **THEN** after the local profile update, `refreshStreaksFromServer()` is invoked in a Task and the previous in-flight refresh (if any) is cancelled

#### Scenario: Refresh failure does not surface
- **WHEN** `refreshStreaksFromServer()` throws (network offline) during the fire-and-forget refresh
- **THEN** `save(_:)` still returns normally and `serverStreaks` retains its previous value

### Requirement: downloadAndReplaceFromServer awaits a streak refresh
`CheckInUseCase.downloadAndReplaceFromServer()` SHALL call `try? await refreshStreaksFromServer()` after `try await replaceAll(checkIns)` so the server-derived streak is consistent with the freshly-pulled check-in history. A streak-refresh error SHALL be swallowed (the check-ins are already replaced).

#### Scenario: Fresh post-login download
- **WHEN** `downloadAndReplaceFromServer()` runs after a fresh login
- **THEN** by the time it returns, either `serverStreaks` reflects the new check-ins or the existing cache is unchanged

## ADDED Requirements

### Requirement: CheckInUseCase is @Observable and holds a serverStreaks cache
`CheckInUseCase` SHALL be declared `@Observable @MainActor final class` and SHALL expose `private(set) var serverStreaks: ServerStreakStats?` as a reactive property. The `init()` SHALL hydrate `serverStreaks` from `userDefaultsStore.data(for: .serverStreakStats)` (decoded as `ServerStreakStats` via JSON). Failure to decode SHALL leave `serverStreaks` as `nil`.

#### Scenario: Hydration on init
- **WHEN** a `ServerStreakStats` blob is present in `UserDefaults` under `.serverStreakStats` AND the use case is initialised
- **THEN** `serverStreaks` equals the decoded blob

#### Scenario: Missing cache
- **WHEN** no blob exists under `.serverStreakStats`
- **THEN** `serverStreaks` is `nil` after init

#### Scenario: Corrupt cache
- **WHEN** the blob exists but fails to decode
- **THEN** `serverStreaks` is `nil` and no error is raised

### Requirement: refreshStreaksFromServer fetches, assigns, persists, and reloads widgets
`CheckInUseCase.refreshStreaksFromServer()` SHALL fetch from `StreaksService.fetchMyStreaks(timezone: TimeZone.current.identifier)`, map the response into a `ServerStreakStats`, assign it to `self.serverStreaks`, persist the JSON-encoded blob via `userDefaultsStore.setData(...)` under `.serverStreakStats`, and call `WidgetCenter.shared.reloadAllTimelines()` so the streak / check-in widgets pick up the new value. On thrown network errors the method SHALL rethrow without mutating `serverStreaks`, the cache, or reloading widgets.

#### Scenario: Successful refresh updates cache and widgets
- **WHEN** `refreshStreaksFromServer()` is called and the backend returns `{ currentStreak: 5, longestStreak: 12, ... }`
- **THEN** `serverStreaks` becomes `ServerStreakStats(currentStreak: 5, longestStreak: 12, ...)` AND the JSON blob is written to App Group UserDefaults under `.serverStreakStats` AND `WidgetCenter.shared.reloadAllTimelines()` is invoked

#### Scenario: Failed refresh preserves cache
- **WHEN** `refreshStreaksFromServer()` is called offline AND `serverStreaks` was previously set
- **THEN** the method throws a `StreaksError` AND `serverStreaks` retains its previous value AND no widget reload is requested

#### Scenario: Timezone is the device's current zone
- **WHEN** `refreshStreaksFromServer()` runs in a simulator with `TimeZone.current.identifier == "America/Los_Angeles"`
- **THEN** the service request includes `?tz=America/Los_Angeles`

### Requirement: CheckInUseCase depends on StreaksService
`CheckInUseCase` SHALL declare `@ObservationIgnored @Injected(\.streaksService) private var streaksService` and SHALL invoke it exclusively from `refreshStreaksFromServer()`. No other method on `CheckInUseCase` SHALL talk to `StreaksService` directly.

#### Scenario: DI container wires StreaksService
- **WHEN** Factory resolves `CheckInUseCase`
- **THEN** `streaksService` is set from `Container.shared.streaksService()`

### Requirement: StreaksService fetches the user's streak stats
The iOS app SHALL define `StreaksServiceProtocol` with one method `fetchMyStreaks(timezone: String) async throws -> StreakStatsResponse`. The concrete `StreaksService` SHALL be a thin Service — it builds the path with a URL-encoded `tz` query value, calls `networkClient.get(...)`, and rethrows via a `private static mapFetchError(_:)`. It SHALL NOT cache, branch, retry, or hold state.

#### Scenario: Request shape
- **WHEN** `streaksService.fetchMyStreaks(timezone: "America/Los_Angeles")` is called
- **THEN** the service GETs `/api/streaks/me?tz=America%2FLos_Angeles`

#### Scenario: 401 maps to StreaksError.unauthorized
- **WHEN** the network client returns 401
- **THEN** the service throws `StreaksError.unauthorized`

#### Scenario: Other failures map to StreaksError.fetchFailed
- **WHEN** the network client throws anything other than a 401
- **THEN** the service throws `StreaksError.fetchFailed`

### Requirement: StreaksError conforms to UserFacingError
The app SHALL define `enum StreaksError: UserFacingError, Equatable` with cases `unauthorized` and `fetchFailed`, each exposing `errorTitle` and `errorDescription`. The enum SHALL live at `Domain/Errors/StreaksError.swift`.

#### Scenario: Error renders into ErrorInfo
- **WHEN** a ViewModel constructs `ErrorInfo(StreaksError.fetchFailed)`
- **THEN** the resulting `ErrorInfo.title` and `ErrorInfo.description` come from the enum case

## REMOVED Requirements

### Requirement: streakStats falls back to a local StreakCalculator when offline
**Reason**: Retaining a local-compute fallback would let any user defeat the server-authoritative streak by going offline and reading the locally-recomputed (and locally-editable) value. The cached `ServerStreakStats` blob is now the only fallback.
**Migration**: `StreakCalculator` is deleted. Callers continue to use `streakStats()` and `streakStartDate()` with unchanged signatures; the return values come from `serverStreaks` or are `(0, 0)` / `nil` when no server result has been fetched yet. `WidgetDataProvider.streakStats()` is rewritten to read the same cached blob via a `WidgetServerStreakStats` mirror struct.
