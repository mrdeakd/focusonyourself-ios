## 1. Backend — Prisma Schema

- [x] 1.1 Add `MeditationSession` model to `prisma/schema.prisma`: `id String @id`, `title String`, `category String`, `durationMinutes Int`, `isPro Boolean`, `steps MeditationStep[]`
- [x] 1.2 Add `MeditationStep` model to `prisma/schema.prisma`: `id Int @id @default(autoincrement())`, `order Int`, `instruction String?`, `silenceDurationSeconds Int?`, `sessionId String`, relation back to `MeditationSession`
- [x] 1.3 Run `npx prisma migrate dev --name add-meditations` to generate migration SQL and apply it locally
- [x] 1.4 Verify migration: `npx prisma studio` — confirm both tables exist with correct columns

## 2. Backend — Seed

- [x] 2.1 Copy `meditations.json` from iOS bundle (`FocusOnYourself/Resources/meditations.json`) to `focusonyourself_backend/prisma/meditations.json`
- [x] 2.2 Add meditation seeding to `prisma/seed.ts` — check if sessions count > 0, skip if so; otherwise upsert each session and its steps with `order` set to array index
- [x] 2.3 Run `npx prisma db seed` and verify 24 sessions and all steps are inserted
- [x] 2.4 Run seed a second time and confirm counts are unchanged (idempotent)

## 3. Backend — Meditations Endpoint

- [x] 3.1 Create `src/routes/meditations.ts` with `GET /` route handler
- [x] 3.2 Define valid categories array: `['morning', 'focus', 'anxiety', 'sleep']`
- [x] 3.3 Implement category validation — return HTTP 400 with error message listing valid values if `?category=` value is not in the valid array
- [x] 3.4 Query sessions with `prisma.meditationSession.findMany()`, include `steps` with `orderBy: { order: 'asc' }`, filter by category when provided
- [x] 3.5 Mount the meditations router in `src/index.ts` at `/api/meditations`
- [x] 3.6 Rebuild Docker: `docker compose up --build`
- [x] 3.7 Verify: `curl "localhost:3005/api/meditations"` returns 24 sessions each with a `steps` array
- [x] 3.8 Verify: `curl "localhost:3005/api/meditations?category=morning"` returns only morning sessions
- [x] 3.9 Verify: `curl "localhost:3005/api/meditations?category=invalid"` returns HTTP 400

## 4. iOS — Remove Unused Methods

- [x] 4.1 Remove `allSessions()` declaration from `MeditationServiceProtocol.swift`
- [x] 4.2 Remove `allSessions()` implementation from `MeditationService.swift`
- [x] 4.3 Remove the `load()` private method and `loaded` cache property from `MeditationService.swift`
- [x] 4.4 Build the iOS project and confirm no compilation errors

## 5. iOS — MeditationService Network Swap

- [x] 5.1 Add `networkClient: NetworkClientProtocol` constructor parameter to `MeditationService`
- [x] 5.2 Update `meditationService` registration in `Container+App.swift` to pass `self.networkClient()`
- [x] 5.3 Make `sessions(for:)` in `MeditationServiceProtocol` `async throws`
- [x] 5.4 Implement `MeditationService.sessions(for:)` — build the path as `/api/meditations` with `?category=<rawValue>` appended when category is non-nil, call `networkClient.get(path)`
- [x] 5.5 Build the iOS project — no compilation errors

## 6. iOS — MeditateViewModel Update

- [x] 6.1 Read `MeditateViewModel.swift` to understand the full current structure before editing
- [x] 6.2 Replace the `filteredSessions` computed property with a stored `var sessions: [MeditationSession] = []`
- [x] 6.3 Add `func loadSessions() async` — calls `meditationService.sessions(for: selectedCategory)`, assigns to `sessions`, handles errors via `self.error`
- [x] 6.4 Update any View that reads `filteredSessions` to read `sessions` instead
- [x] 6.5 Add `.task { await viewModel.loadSessions() }` to the Meditate screen
- [x] 6.6 Add `.onChange(of: viewModel.selectedCategory) { await viewModel.loadSessions() }` so category changes trigger a fresh fetch
- [x] 6.7 Build the iOS project — no compilation errors

## 7. iOS — Cleanup

- [x] 7.1 Delete `FocusOnYourself/Resources/meditations.json` from the iOS project
- [x] 7.2 Build the iOS project — no compilation errors
- [ ] 7.3 Run the app in Simulator with backend running — meditations list loads correctly for all categories
- [ ] 7.4 Switch categories in the UI — verify each category fetches fresh results from the backend
