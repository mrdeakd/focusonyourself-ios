## Context

The backend already has every check-in. `CheckinsService.importAll` and `CheckinsService.post` push them; `BackendCheckIn` rows persist them. Streak computation has so far lived on the iOS device — `StreakCalculator.compute(checkIns:)` runs against the in-memory `[CheckIn]` array on every read of `HomeViewModel.streakCount` and `HistoryViewModel.streakStats`. Those reads are synchronous and frequent. `WidgetDataProvider.streakStats()` re-implements the same algorithm against the App Group `userProfile` blob so widgets can render without an extension host process.

Moving streaks to the backend cannot break that synchronous read pattern without rippling into both screens, the `CheckInUseCaseProtocol`, and the widgets. So the design is "synchronous reads from a cached server result, with periodic refresh from the network." There is no local-compute fallback — `StreakCalculator` is deleted entirely, because retaining it would let any user defeat the server-authoritative model simply by going offline.

The check-in data shape is timezone-stable: `CheckIn.dateString` is `YYYY-MM-DD` in the device's local timezone at check-in time. Streak math over those strings doesn't need a timezone — except for the "current streak" anchor, which depends on what "today" is. Hence the `?tz=` query parameter.

## Goals / Non-Goals

**Goals:**
- Backend is the source of truth for `currentStreak` and `longestStreak`
- iOS keeps synchronous `streakStats()` / `streakStartDate()` — call sites are unmodified
- Cached `ServerStreakStats` blob in App Group UserDefaults is the **only** offline / cold-start source, shared by the main app and widgets
- Refresh happens on check-in mutation and on screen appear

**Non-Goals:**
- Local-compute fallback — explicitly removed. A user with no server data sees `(current: 0, longest: 0)` until the first successful fetch.
- Server-side anti-cheat heuristics beyond "trust the check-in rows we already have" — out of scope; if backend check-in writes need stricter validation, that's a separate change
- Async-await `streakStats()` API — would force every call site to wrap in `Task`; the cost is not worth it for a derived number
- Push notifications for streak milestones — separate feature

## Decisions

### 1. Reuse the existing `CheckIn` table — no new schema

The backend already stores every user's check-ins via `POST /api/checkins/import` and `POST /api/checkins`. The streak endpoint queries that same table — no migrations, no new model.

```typescript
const checkIns = await prisma.checkIn.findMany({
  where: { userId: req.user.id },
  select: { dateString: true },
  orderBy: { dateString: 'asc' },
})
```

*Alternatives considered:* A materialised `Streak` table updated on every check-in write — saves a few ms per request but adds write-amplification, migration complexity, and a consistency invariant we have to maintain. With current check-in volumes (< 1000 per user), the live query is fine.

### 2. `computeStreaks(dateStrings, todayDateString)` helper

A single backend implementation — there is no client implementation to keep in sync with:

```typescript
function computeStreaks(dateStrings: string[], today: string): {
  current: number; longest: number; startDate: string | null; lastCheckIn: string | null
} {
  const set = new Set(dateStrings)
  const sorted = [...set].sort()

  // current: walk back from today (or yesterday if today is missing)
  let day = set.has(today) ? today : prevDay(today)
  let current = 0
  let startDate: string | null = null
  while (set.has(day)) {
    current += 1
    startDate = day
    day = prevDay(day)
  }

  // longest: scan sorted list for consecutive runs
  let longest = 0
  let run = 0
  let prev: string | null = null
  for (const d of sorted) {
    run = prev && nextDay(prev) === d ? run + 1 : 1
    if (run > longest) longest = run
    prev = d
  }

  return { current, longest, startDate, lastCheckIn: sorted.at(-1) ?? null }
}
```

`prevDay` / `nextDay` work in YYYY-MM-DD by parsing → `Date` → `setUTCDate(±1)` → reformat. Pure string math; no DST surprises.

### 3. `?tz=` only anchors "today"; the rest is timezone-free

The longest-streak calculation is over `dateString` values that are already in the user's local timezone at the moment of check-in. The only place "today" matters is the current-streak walk-back. The server resolves the user's "today" by:

```typescript
const tz = parseTz(req.query.tz) ?? 'UTC'
const today = new Date().toLocaleDateString('en-CA', { timeZone: tz })  // YYYY-MM-DD
```

`parseTz` returns the input only if it's a known IANA name (try/catch around `Intl.DateTimeFormat({ timeZone })`); otherwise `null` and we fall back to UTC.

*Alternatives considered:* Have iOS pass `?today=2026-05-25` directly — works, but lets a tampering client pick a "today" several days in the future to falsely extend the streak. Letting the server resolve "today" from a timezone constrains the abuse window to ±1 day, which is the natural ambiguity of a timezone boundary anyway.

### 4. `ServerStreakStats` domain model is a plain `Codable` struct

```swift
struct ServerStreakStats: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let streakStartDate: Date?
    let lastCheckInDate: Date?
}
```

Wire shape matches the domain shape exactly. No mapper needed.

### 5. `CheckInUseCase` becomes `@Observable @MainActor final class`

Adding `@Observable` is necessary so that updates to `serverStreaks` propagate through to the VMs' computed properties that read `streakStats()`. The existing `var hasCheckedInToday`, `var todaysMood`, etc. computed properties already chain off `profileUseCase.profile.checkIns` (which is `@Observable` on `ProfileUseCase`), so they continue working. The new `private(set) var serverStreaks: ServerStreakStats?` adds the second reactive source. The `streakCalculator` instance variable is removed.

```swift
@Observable @MainActor final class CheckInUseCase: CheckInUseCaseProtocol {
    @ObservationIgnored @Injected(\.profileUseCase) private var profileUseCase
    @ObservationIgnored @Injected(\.checkinsService) private var checkinsService
    @ObservationIgnored @Injected(\.streaksService) private var streaksService
    @ObservationIgnored @Injected(\.userDefaultsStore) private var userDefaultsStore
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    private(set) var serverStreaks: ServerStreakStats?

    init() {
        if let data = userDefaultsStore.data(for: .serverStreakStats),
           let cached = try? JSONDecoder().decode(ServerStreakStats.self, from: data) {
            serverStreaks = cached
        }
    }
    // ...
}
```

### 6. `streakStats()` and `streakStartDate()` read only from the server cache

```swift
func streakStats() -> (current: Int, longest: Int) {
    guard let s = serverStreaks else { return (current: 0, longest: 0) }
    return (s.currentStreak, s.longestStreak)
}

func streakStartDate() -> Date? {
    serverStreaks?.streakStartDate
}
```

VMs continue to call these synchronously. Whenever `serverStreaks` changes (via `refreshStreaksFromServer()`), `@Observable` triggers a re-read. A user with no cached server result yet sees `0` until the first successful fetch — by design, since the cache is the only fallback.

### 6a. `StreakCalculator` is deleted

`FocusOnYourself/Domain/Calculators/StreakCalculator.swift` is removed. Keeping it as an "offline fallback" would let any user bypass server authority by toggling airplane mode and reading the locally-computed (and locally-editable) streak. The cached `ServerStreakStats` blob already covers cold-start render and short-term offline display. The only state required for offline correctness is "the last value the server told us," which is exactly what the cache holds.

### 6b. Widgets read the same cached blob from the App Group

`UserDefaultsStore` already writes to the App Group suite (`group.app.ddworks.FocusOnYourself`), so the cached `ServerStreakStats` JSON blob under the key `"server-streak-stats"` is automatically visible to the widget extension. `WidgetDataProvider.streakStats()` is rewritten to decode this blob via a mirror struct:

```swift
private struct WidgetServerStreakStats: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let streakStartDate: Date?
    let lastCheckInDate: Date?
}

static func streakStats() -> (current: Int, longest: Int) {
    guard
        let defaults = UserDefaults(suiteName: suiteName),
        let data = defaults.data(forKey: "server-streak-stats"),
        let stats = try? JSONDecoder().decode(WidgetServerStreakStats.self, from: data)
    else { return (current: 0, longest: 0) }
    return (current: stats.currentStreak, longest: stats.longestStreak)
}
```

`WidgetServerStreakStats` follows the existing "main app and widget hold field-for-field mirror types" convention in `WidgetDataProvider.swift`. The local algorithm (lines 81–113 of `WidgetDataProvider.swift`) is deleted.

The main app is responsible for calling `WidgetCenter.shared.reloadAllTimelines()` after `refreshStreaksFromServer()` so the widget picks up the new blob — this is already done by `ProfileUseCase` after profile updates, and we add an analogous reload after streak refresh.

### 7. Refresh is fire-and-forget after mutations; explicit on screen appear

```swift
func refreshStreaksFromServer() async throws {
    let tz = TimeZone.current.identifier
    let response = try await streaksService.fetchMyStreaks(timezone: tz)
    let stats = ServerStreakStats(
        currentStreak: response.currentStreak,
        longestStreak: response.longestStreak,
        streakStartDate: response.streakStartDate,
        lastCheckInDate: response.lastCheckInDate
    )
    serverStreaks = stats
    if let data = try? JSONEncoder().encode(stats) {
        userDefaultsStore.setData(data, for: .serverStreakStats)
    }
    WidgetCenter.shared.reloadAllTimelines()
}

private func save(_ checkIn: CheckIn) async throws {
    // ... existing logic ...
    Task { try? await checkinsService.post(checkIn) }
    refreshTask?.cancel()
    refreshTask = Task { [weak self] in try? await self?.refreshStreaksFromServer() }
}
```

The mutation-driven refresh is fire-and-forget per the project's "Fire-and-forget exception" rule: (1) local check-in is already persisted in `ProfileUseCase`, (2) a failed refresh has no user-visible consequence beyond the headline number showing the previous cached value, (3) reason: streak displays are advisory until the next explicit refresh.

VM-side, `HomeViewModel` and `HistoryViewModel` already have an `onAppear()` (or equivalent) entry point. We add `Task { try? await checkInUseCase.refreshStreaksFromServer() }` there.

### 8. `StreaksService` follows the standard thin Service pattern

```swift
final class StreaksService: StreaksServiceProtocol {
    private let networkClient: NetworkClientProtocol
    init(networkClient: NetworkClientProtocol) { self.networkClient = networkClient }

    func fetchMyStreaks(timezone: String) async throws -> StreakStatsResponse {
        let path = "/api/streaks/me?tz=\(timezone.urlEncoded)"
        do {
            let response: StreakStatsResponse = try await networkClient.get(path)
            return response
        } catch {
            throw Self.mapFetchError(error)
        }
    }

    private static func mapFetchError(_ error: Error) -> StreaksError {
        switch (error as? NetworkError)?.statusCode {
        case 401: .unauthorized
        default:  .fetchFailed
        }
    }
}
```

## Risks / Trade-offs

**[Risk] Brand-new user with no backend round-trip yet sees streak `0`** → Accepted. On first launch the cache is empty, so `streakStats()` returns `(0, 0)` until the first successful `refreshStreaksFromServer()` resolves — typically within a few hundred ms of opening the app while signed in. The first user-visible streak number ever shown is the server's number, which is the desired behaviour.

**[Risk] User goes offline with stale cache and the server later corrects the streak** → The cache holds the last value the server told us. When the user comes back online, the next refresh updates the cache. There is no way for an offline user to inflate their streak — that's the entire point of removing the local fallback.

**[Risk] Backend unreachable on `onAppear` ⇒ stats appear "frozen" at the cached value** → Acceptable. The cached value is the last server-authorised number, which is still the right answer to show. Users typically don't notice a one-call lag, and the value reconciles on the next successful fetch.

**[Risk] Timezone change mid-day** → If a user crosses a timezone boundary, "today" shifts. The server uses the timezone the iOS app sends *at refresh time*. The next refresh after the change picks up the new timezone. Edge cases (e.g. checked in at 11pm in NYC, flew to LA, refreshes at 1am LA-time which is 4am NYC) are inherent to streak features and out of scope to fix here.

**[Risk] Adding `@Observable` to `CheckInUseCase` re-renders any view that reads `checkInUseCase.todaysMood` whenever `serverStreaks` changes** → Per SwiftUI's `@Observable` model, dependency tracking is per-property: a view reading `todaysMood` only re-renders when `profileUseCase.profile.checkIns` changes, not when `serverStreaks` does. So the change is invisible in practice.

**[Risk] `refreshStreaksFromServer()` races with `save(_:)`'s network sync** → `save(_:)` first updates local state (synchronous), then fire-and-forgets the network post AND a streak refresh. If the streak refresh happens before the check-in arrives on the server (unlikely since both go on `URLSession`, but possible), the server returns the pre-write streak — the cached value briefly trails reality. The next refresh on `onAppear` corrects it. Acceptable since the staleness window is bounded by the next user navigation.

**[Risk] Widget can show `0` immediately after install before the main app has refreshed** → Same UX as a brand-new user: until the first server fetch, widgets read no cached blob and render `0`. Once the main app opens and refreshes, `WidgetCenter.shared.reloadAllTimelines()` propagates the new value.

## Migration Plan

1. Backend: add `src/services/streakCalculator.ts` helper with unit tests for known inputs (empty, today-only, three-day consecutive, broken streak, today missing)
2. Backend: add `src/routes/streaks.ts` with `GET /me`, mount under `/api/streaks` in `src/index.ts`
3. Backend: rebuild Docker, verify with `curl -H "Authorization: Bearer <token>" "localhost:3005/api/streaks/me?tz=America/Los_Angeles"`
4. iOS: add `ServerStreakStats.swift`, `StreakStatsResponse.swift`, `StreaksError.swift`, `StreaksService` + protocol
5. iOS: add `UserDefaultsKey.serverStreakStats`
6. iOS: register `streaksService` in `Container+App.swift`
7. iOS: convert `CheckInUseCase` to `@Observable @MainActor final class`, add `serverStreaks` cache + `refreshStreaksFromServer()`, remove `streakCalculator` member
8. iOS: rewrite `streakStats()` / `streakStartDate()` to read only from `serverStreaks` (return `(0, 0)` / `nil` when empty)
9. iOS: wire fire-and-forget refresh into `save(_:)` and `downloadAndReplaceFromServer()`; call `WidgetCenter.shared.reloadAllTimelines()` after a successful refresh
10. iOS: add `refreshStreaksFromServer()` call to `HomeViewModel` and `HistoryViewModel` on-appear paths
11. Widget: rewrite `WidgetDataProvider.streakStats()` to decode the cached `WidgetServerStreakStats` blob; delete the in-process algorithm
12. iOS: delete `FocusOnYourself/Domain/Calculators/StreakCalculator.swift`
13. iOS: build (`xcodebuild ... | tail -20`), simulator, log in, perform a check-in; confirm the streak number on Home matches the backend's response and the StreakWidget reloads with the same number
14. iOS: delete the cached `server-streak-stats` blob from App Group UserDefaults, kill network, relaunch — confirm `streakStats()` returns `(0, 0)` and the widget shows `0`
