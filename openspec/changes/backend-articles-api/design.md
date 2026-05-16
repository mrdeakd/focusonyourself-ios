## Context

Articles are currently loaded from a bundled `articles.json` file inside the iOS app via `Bundle.decodeJSON`. The `ArticlesService` decodes the JSON once, caches it in memory, and applies a date-seeded shuffle to return 4 articles per day. There is no network layer in the app today.

This design introduces a minimal Node.js backend project (`focusonyourself_backend/`) and replaces the bundle read with a single API call, keeping all existing iOS interfaces identical.

## Goals / Non-Goals

**Goals:**
- Stand up a working Node.js + TypeScript + Express + Prisma + SQLite backend project, containerised with Docker
- Serve `GET /api/articles/daily` with identical daily-rotation behaviour to current iOS logic
- Add a thin `NetworkClient` to iOS that `ArticlesService` uses — no other call sites change
- Keep `HomeViewModel` and all UI code completely untouched
- Produce `LEARN.md` documenting every tool, command, and concept used

**Non-Goals:**
- Caching on iOS (Phase 2+)
- Offline fallback to bundle (can be added later)
- Authentication or subscription enforcement on the backend
- Deploying the backend anywhere (localhost only for this phase)
- Migrating meditations, affirmations, or audio (Phases 2–4)

## Decisions

### 1. TypeScript over plain JavaScript
TypeScript gives type-safe `Article` models that mirror the Swift structs exactly, catches shape mismatches at compile time, and is worth learning from the start. The overhead is minimal (`ts-node-dev` runs TypeScript directly in dev mode, `tsc` builds for production).

*Alternatives considered:* Plain JS — simpler setup but loses type safety; JSDoc — middle ground but awkward.

### 2. Express.js over Fastify / Hono
Express is the most-documented Node.js framework with the largest tutorial surface area, making it the best fit for learning. Performance differences don't matter for a local dev server with light traffic.

*Alternatives considered:* Fastify — faster, better TypeScript support, but steeper learning curve; Hono — modern but less ecosystem coverage.

### 3. Prisma + SQLite over raw SQLite / PostgreSQL
Prisma provides a typed query builder, a declarative schema file, and a migration system — all valuable things to learn. SQLite needs zero installation and runs as a single file, removing setup friction entirely. The combination is the fastest path from "zero" to "working DB + ORM".

*Alternatives considered:* `better-sqlite3` (raw) — good for learning SQL but no schema/migration tooling; PostgreSQL — more production-realistic but requires a running server process.

### 4. Date-seeded shuffle algorithm ported to TypeScript
The current Swift implementation hashes the date string (`YYYY-MM-DD`) to an integer seed, then uses that seed to shuffle the full article list and returns the first 4. The TypeScript port uses:
- `seedrandom` npm package for a seedable PRNG (equivalent to Swift's `var rng = SeededRandomNumberGenerator`)
- Same date string format as the iOS code to guarantee identical results on the same day

The `date` query parameter defaults to today's UTC date if omitted, so iOS can pass `?date=YYYY-MM-DD` explicitly for determinism in tests.

*Alternatives considered:* Pure modulo rotation — simpler but doesn't produce the same spread as the shuffle; server-side "today" — removes the query param but makes the endpoint non-deterministic for testing.

### 5. Protocol-based Networking layer in a dedicated `Networking/` folder
The networking layer lives at `FocusOnYourself/Networking/` and consists of three files:

| File | Role |
|---|---|
| `NetworkClientProtocol.swift` | Protocol — the only type services import |
| `URLSessionNetworkClient.swift` | Concrete implementation using `URLSession` |
| `NetworkError.swift` | Typed errors: `invalidURL`, `badResponse(Int)` |

`NetworkClientProtocol` declares a single method:
```swift
protocol NetworkClientProtocol {
    func get<T: Decodable>(_ path: String) async throws -> T
}
```

`URLSessionNetworkClient` is a value type (`struct`) holding a `baseURL` and implementing the protocol via `URLSession.shared`. It is registered in `Container+App.swift` as a singleton and injected into services via constructor — matching the existing pattern used by `ProfileService`:

```swift
// Container+App.swift
var networkClient: Factory<NetworkClientProtocol> {
    self { URLSessionNetworkClient(baseURL: URL(string: "http://localhost:3000")!) }.singleton
}

var articlesService: Factory<ArticlesServiceProtocol> {
    self { ArticlesService(networkClient: self.networkClient()) }.singleton
}
```

Using a protocol rather than a concrete type keeps `ArticlesService` testable without networking, and makes the layer reusable across all future phases (meditations, affirmations) without any architectural changes — each new service just receives the same injected `NetworkClientProtocol`.

*Alternatives considered:* Concrete `NetworkClient` struct with no protocol — simpler, but not injectable/mockable; `@Injected` in the service rather than constructor injection — works, but constructor injection is the established pattern for service dependencies in this codebase.

### 6. Docker for containerised local development
The backend runs inside a Docker container managed by `docker compose`. This means:
- A single `docker compose up` command handles building the image, running migrations, seeding the DB, and starting the server
- The SQLite database file is stored on a named Docker volume so data survives `docker compose down`
- The container exposes port `3000` to the host, so iOS Simulator can reach it at `http://localhost:3000` unchanged
- `LEARN.md` covers Dockerfile anatomy, `docker compose.yml` structure, volumes, and common commands

*Alternatives considered:* Running Node directly with `npm run dev` — simpler, but misses the Docker learning opportunity and makes the dev environment less portable; PostgreSQL in Docker — more production-like but adds unnecessary complexity for Phase 1.

### 7. HTTP allowed on iOS simulator without ATS changes
iOS App Transport Security (ATS) blocks HTTP in production but `localhost` is **exempt by default** — no `NSAppTransportSecurity` entry needed in `Info.plist` for simulator testing. This keeps the iOS changes minimal.

## Risks / Trade-offs

**[Risk] Backend must be running for the app to work** → The app will show an empty articles section (or an error state) if the backend is offline. This is acceptable for local development; offline fallback is a Phase 2 concern.

**[Risk] Date-seed parity between Swift and TypeScript** → If the hash or shuffle algorithm differs between platforms, articles will rotate differently. Mitigation: write a cross-check — call both the old iOS bundle path and the new API on the same date and compare results during transition. Document the algorithm in `LEARN.md`.

**[Risk] `articles.json` schema drift** → If the JSON structure in the backend DB diverges from the iOS `Article` Codable struct, decoding will silently fail. Mitigation: the Prisma schema is typed to match the Swift struct field-for-field; any rename in one must be applied to the other.

## Migration Plan

1. Create `focusonyourself_backend/` with `Dockerfile`, `docker-compose.yml`, TypeScript config, Prisma schema, and seed script
2. Start backend: `docker compose up` → migrations run, DB seeded, server on `localhost:3000`
3. Verify: `curl "localhost:3000/api/articles/daily?date=$(date +%F)"` returns 4 articles
4. Add `NetworkClient.swift` to the iOS project
5. Update `ArticlesService.swift` to call the API; remove unused protocol methods
6. Run iOS app in Simulator — verify articles section renders correctly
7. Confirm same 4 articles appear as before the migration (same date seed)
8. Build check: `xcodebuild ... build 2>&1 | tail -20` — no errors
