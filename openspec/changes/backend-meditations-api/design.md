## Context

Meditation sessions are loaded from a bundled `meditations.json` via `Bundle.decodeJSON` in `MeditationService`. The data has a nested structure — each session contains an ordered array of steps — which makes this phase meaningfully different from Phase 1 (Articles). Articles were flat; meditations require a one-to-many relation in the database.

The iOS app has one active caller: `MeditateViewModel.filteredSessions`, a synchronous computed property that calls `meditationService.sessions(for: selectedCategory)`. Making the service async requires converting this computed property to a stored property loaded via a Task.

The `MeditationPlayerViewModel` receives a `MeditationSession` as a parameter and is entirely unaffected — it never touches the service.

## Goals / Non-Goals

**Goals:**
- Add `MeditationSession` and `MeditationStep` Prisma models with a one-to-many relation
- Seed all 24 sessions (with steps) from `meditations.json`
- Expose `GET /api/meditations?category=<category>` returning sessions with nested steps
- Replace `MeditationService` bundle loading with a network call using the existing `NetworkClientProtocol`
- Remove `meditations.json` from the iOS bundle
- Remove unused `allSessions()` from the protocol

**Non-Goals:**
- Audio playback — `MeditationAudioService` and narration MP3s are Phase 4
- Pro/Free gating on the backend — `isPro` field is returned but enforcement stays on iOS
- Pagination — 24 sessions is small enough to return in one response

## Decisions

### 1. Two-table schema with explicit `order` column on steps

`MeditationSession` and `MeditationStep` become separate Prisma models. Each step gets an `order: Int` column so the server can return steps sorted correctly with `orderBy: { order: 'asc' }`. Without an explicit order field, the database makes no guarantee about row sequence.

```prisma
model MeditationSession {
  id              String           @id
  title           String
  category        String
  durationMinutes Int
  isPro           Boolean
  steps           MeditationStep[]
}

model MeditationStep {
  id                     Int              @id @default(autoincrement())
  order                  Int
  instruction            String?
  silenceDurationSeconds Int?
  sessionId              String
  session                MeditationSession @relation(fields: [sessionId], references: [id])
}
```

*Alternatives considered:* Storing steps as a JSON column (`String`) — simpler schema but loses queryability and type safety. Rejected because Prisma relations are a key learning concept for this phase.

### 2. Endpoint returns sessions with steps nested (single request)

`GET /api/meditations` returns the full session list including steps inline:
```json
[
  {
    "id": "morning-001",
    "title": "...",
    "steps": [
      { "order": 0, "instruction": "...", "silenceDurationSeconds": null },
      ...
    ]
  }
]
```

This mirrors the shape of the Swift `MeditationSession` struct exactly — `steps` is an array nested inside each session. The iOS `JSONDecoder` decodes it without any changes to the model.

*Alternatives considered:* Separate `/api/meditations/:id/steps` endpoint — more RESTful but requires two requests per session load. Rejected because the iOS app always needs both session metadata and steps together.

### 3. Category filtering on the backend via query param

`?category=morning` filters at the database level using Prisma's `where` clause. If omitted, all sessions are returned. This avoids sending 24 sessions when only 4-6 are needed.

*Alternatives considered:* Return all sessions and filter on iOS — simpler backend but wastes bandwidth. Articles used this approach (no filtering needed), but meditations have a real filter UI.

### 4. `MeditateViewModel` loads sessions on appear, stored property replaces computed

`filteredSessions` changes from:
```swift
var filteredSessions: [MeditationSession] { meditationService.sessions(for: selectedCategory) }
```
to a stored `var sessions: [MeditationSession] = []` refreshed by `loadSessions()` async. When `selectedCategory` changes, `loadSessions()` is called again. The View observes `sessions` directly.

*Alternatives considered:* Keeping a computed property with an `async` getter — not supported in Swift. Task wrapper inside the ViewModel — adds complexity; async function called from `.task {}` and `.onChange {}` is cleaner.

### 5. Seed extends existing `seed.ts` — no new file

The meditation seed logic is added to the existing `prisma/seed.ts` alongside articles. The skip-if-exists check is extended per model: seed articles only if articles table is empty, seed sessions only if sessions table is empty.

## Risks / Trade-offs

**[Risk] Steps are seeded with explicit order index from JSON array position** → The seed assigns `order` by the array index in `meditations.json`. If the JSON order ever changes, a `down -v` + reseed is needed. Acceptable for this stage.

**[Risk] `MeditateViewModel` shows empty list briefly on appear** → Between screen mount and `loadSessions()` completing, `sessions` is `[]`. Mitigation: show a loading state or let the list render empty then populate — same pattern as articles.

**[Risk] Category filter string must match exactly** → `?category=morning` is matched against the `category` column as a string. A typo returns an empty array with HTTP 200, not an error. Mitigation: validate against known values in the route handler and return 400 for unknown categories.

## Migration Plan

1. Add `MeditationSession` and `MeditationStep` to `prisma/schema.prisma`
2. Run `npx prisma migrate dev --name add-meditations` locally to generate migration SQL
3. Extend `prisma/seed.ts` to seed sessions + steps
4. Add `src/routes/meditations.ts` and mount it in `src/index.ts`
5. Rebuild Docker: `docker compose up --build`
6. Verify endpoint: `curl "localhost:3005/api/meditations?category=morning"`
7. Update iOS `MeditationServiceProtocol`, `MeditationService`, `MeditateViewModel`, `Container+App.swift`
8. Delete `meditations.json` from iOS bundle
9. Build iOS: `xcodebuild ... build 2>&1 | tail -20`
