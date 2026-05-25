## 1. Backend — Shared Streak Helper

- [ ] 1.1 Create `src/services/streakCalculator.ts` exporting `computeStreaks(dateStrings: string[], today: string)` per design §2
- [ ] 1.2 Add inline `prevDay` / `nextDay` helpers that operate on `YYYY-MM-DD` strings via UTC `Date` arithmetic
- [ ] 1.3 Add a `parseTz(input)` helper that returns the input only if `new Intl.DateTimeFormat('en-CA', { timeZone: input })` doesn't throw, else `null`
- [ ] 1.4 Add minimal unit-test cases (or a one-off script that asserts known outputs) for: empty list, single date today, three-day consecutive ending today, broken streak

## 2. Backend — Streaks Endpoint

- [ ] 2.1 Create `src/routes/streaks.ts` with `GET /me` handler behind `requireAuth`
- [ ] 2.2 Parse `?tz=` via `parseTz`; fall back to `'UTC'` when missing or invalid
- [ ] 2.3 Compute `today` as `new Date().toLocaleDateString('en-CA', { timeZone: tz })`
- [ ] 2.4 Query `prisma.checkIn.findMany({ where: { userId: req.user.id }, select: { dateString: true }, orderBy: { dateString: 'asc' } })`
- [ ] 2.5 Call `computeStreaks(rows.map(r => r.dateString), today)`
- [ ] 2.6 Return `{ currentStreak, longestStreak, streakStartDate, lastCheckInDate }` — date fields formatted as ISO8601 by appending `T00:00:00Z` to the `YYYY-MM-DD` string (or `null`)
- [ ] 2.7 Mount router in `src/index.ts` at `/api/streaks`

## 3. Backend — Verify

- [ ] 3.1 `npm run build`
- [ ] 3.2 `docker compose up --build`
- [ ] 3.3 Seed a test user with known check-ins via existing endpoints
- [ ] 3.4 `curl -H "Authorization: Bearer <token>" "localhost:3005/api/streaks/me?tz=UTC"` returns plausible numbers
- [ ] 3.5 Repeat with `?tz=America/Los_Angeles` — verify `currentStreak` may differ by ±1 depending on the day boundary
- [ ] 3.6 `curl ... "localhost:3005/api/streaks/me?tz=Not/A_Real_Zone"` — verify it falls back to UTC (no error)
- [ ] 3.7 `curl` without `Authorization` returns HTTP 401

## 4. iOS — Domain Model and Wire Model

- [ ] 4.1 Create `Domain/Models/ServerStreakStats.swift` — `struct ServerStreakStats: Codable, Equatable { let currentStreak: Int; let longestStreak: Int; let streakStartDate: Date?; let lastCheckInDate: Date? }`
- [ ] 4.2 Create `Networking/Models/StreakStatsResponse.swift` with the same field shape — wire model
- [ ] 4.3 Create `Domain/Errors/StreaksError.swift` — `enum StreaksError: UserFacingError, Equatable { case unauthorized, fetchFailed }` with `errorTitle` and `errorDescription`
- [ ] 4.4 Add `case serverStreakStats = "server-streak-stats"` to `UserDefaultsKey`

## 5. iOS — StreaksService

- [ ] 5.1 Create `Services/Streaks/StreaksServiceProtocol.swift` — `protocol StreaksServiceProtocol { func fetchMyStreaks(timezone: String) async throws -> StreakStatsResponse }`
- [ ] 5.2 Create `Services/Streaks/StreaksService.swift` per design §8 — `final class`, injects `networkClient`, `do/catch` + `mapFetchError(_:)` static
- [ ] 5.3 URL-encode the `tz` query value (`addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)`)
- [ ] 5.4 Register in `Container+App.swift` under `// MARK: - Services`: `var streaksService: Factory<StreaksServiceProtocol> { self { @MainActor in StreaksService(networkClient: self.networkClient()) }.singleton }`

## 6. iOS — CheckInUseCase Rewrite

- [ ] 6.1 Add `@Observable @MainActor` attributes to `CheckInUseCase`
- [ ] 6.2 Add `@ObservationIgnored @Injected(\.streaksService) private var streaksService`
- [ ] 6.3 Add `@ObservationIgnored private var refreshTask: Task<Void, Never>?`
- [ ] 6.4 Add `private(set) var serverStreaks: ServerStreakStats?` (the reactive surface)
- [ ] 6.5 Add `init()` that decodes the cached `ServerStreakStats` from `userDefaultsStore.data(for: .serverStreakStats)` and assigns to `serverStreaks`
- [ ] 6.6 Add `func refreshStreaksFromServer() async throws` per design §7 — fetch via `streaksService`, build `ServerStreakStats`, assign to `serverStreaks`, persist via `userDefaultsStore.setData(...)`, then call `WidgetCenter.shared.reloadAllTimelines()`
- [ ] 6.7 Rewrite `streakStats()` to return `(serverStreaks?.currentStreak ?? 0, serverStreaks?.longestStreak ?? 0)` — no fallback to a local calculator
- [ ] 6.8 Rewrite `streakStartDate()` to return `serverStreaks?.streakStartDate` — no fallback to a local calculator
- [ ] 6.9 In `save(_:)`, after the existing `Task { try? await checkinsService.post(checkIn) }`, cancel the old `refreshTask` and start a new one: `refreshTask = Task { [weak self] in try? await self?.refreshStreaksFromServer() }`
- [ ] 6.10 In `downloadAndReplaceFromServer()`, after `try await replaceAll(checkIns)`, call `try? await refreshStreaksFromServer()` (sequential — the caller is already async)
- [ ] 6.11 Add `var serverStreaks: ServerStreakStats? { get }` and `func refreshStreaksFromServer() async throws` to `CheckInUseCaseProtocol`
- [ ] 6.12 Remove the `private let streakCalculator = StreakCalculator()` declaration from `CheckInUseCase`

## 7. iOS — ViewModel Wiring

- [ ] 7.1 In `HomeViewModel`, add (or extend an existing) `onAppear()` method that fires `Task { try? await checkInUseCase.refreshStreaksFromServer() }`
- [ ] 7.2 Wire `HomeScreen.onAppear { viewModel.onAppear() }`
- [ ] 7.3 In `HistoryViewModel`, do the same — refresh on appear
- [ ] 7.4 Wire `HistoryScreen.onAppear { viewModel.onAppear() }`

## 8. Widget — Mirror and Data Provider Rewrite

- [ ] 8.1 In `FocusOnYourselfWidgets/WidgetDataProvider.swift`, add `private struct WidgetServerStreakStats: Codable { let currentStreak: Int; let longestStreak: Int; let streakStartDate: Date?; let lastCheckInDate: Date? }` — field-for-field mirror of the main app's `ServerStreakStats`
- [ ] 8.2 Add a constant `private static let serverStreakStatsKey = "server-streak-stats"` matching the `UserDefaultsKey.serverStreakStats` raw value
- [ ] 8.3 Rewrite `WidgetDataProvider.streakStats()` to decode the cached blob: `UserDefaults(suiteName: suiteName)?.data(forKey: serverStreakStatsKey)` → `JSONDecoder().decode(WidgetServerStreakStats.self, from: data)` → `(current: stats.currentStreak, longest: stats.longestStreak)`; return `(0, 0)` on any failure
- [ ] 8.4 Delete the previous in-process streak computation (lines computing `current` / `longest` from `profile.checkIns`)
- [ ] 8.5 Confirm `CheckInWidget.swift` and `StreakWidget.swift` still compile — they consume `WidgetDataProvider.streakStats()` unchanged

## 9. iOS — Delete StreakCalculator

- [ ] 9.1 Remove the `import` (if any references remain) and delete `FocusOnYourself/Domain/Calculators/StreakCalculator.swift`
- [ ] 9.2 `grep -rn "StreakCalculator" FocusOnYourself FocusOnYourselfWidgets --include="*.swift"` — verify zero matches

## 10. iOS — Build and Verify

- [ ] 10.1 `xcodebuild -project FocusOnYourself.xcodeproj -scheme FocusOnYourself -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20` — no errors
- [ ] 10.2 `swiftlint --fix && swiftlint` — no violations
- [ ] 10.3 Run app in simulator with backend running locally, logged in
- [ ] 10.4 With existing check-ins synced to server, open HomeScreen — confirm the streak number matches the backend response in the same TZ
- [ ] 10.5 Open HistoryScreen — confirm "Current Streak" / "Longest Streak" match
- [ ] 10.6 Add a new check-in via the UI — confirm the streak refresh fires and the number updates
- [ ] 10.7 Add `StreakWidget` to the home screen — confirm it shows the same number as the app after a refresh, and that adding a check-in reloads the widget within a few seconds
- [ ] 10.8 Manually delete a row from the backend `CheckIn` table; pull the app to foreground (or revisit Home) — confirm the streak number drops to match
- [ ] 10.9 In a DB client, delete the cached `server-streak-stats` blob from the App Group UserDefaults; force-quit and relaunch offline — confirm `streakStats()` returns `(0, 0)` (both app and widget render `0`)
- [ ] 10.10 Cross-timezone check: change the simulator's timezone to `America/Los_Angeles`, refresh — confirm the request includes `?tz=America/Los_Angeles`
