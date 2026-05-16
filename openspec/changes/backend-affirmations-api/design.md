## Context

`AffirmationService` currently has two paths inside `generateBatch`: Apple Intelligence (on-device AI) and a static dataset path that reads `affirmations.json` from the app bundle. Only the static path moves to the backend. The Apple Intelligence path, the caching layer (`cachedBatch` / `cacheBatch`), and the `AffirmationServiceProtocol` interface are all completely untouched.

The dataset is ~27,000 rows — significantly larger than articles (40) and meditation sessions (24 + steps). Seeding strategy and query performance need explicit attention.

## Goals / Non-Goals

**Goals:**
- Add flat `Affirmation` Prisma model (no relations needed)
- Seed ~27,000 rows efficiently using `createMany`
- Expose `GET /api/affirmations/batch?categories=confidence,mindfulness&count=10` returning a random selection
- Replace only the `loadStaticBatch` path in `AffirmationService` with a network call
- Remove `affirmations.json` from the iOS bundle (−3.5 MB)

**Non-Goals:**
- Apple Intelligence generation path — stays on-device, untouched
- UserDefaults caching — stays on iOS, untouched
- Pro/Free category enforcement — stays on iOS
- Deterministic/seeded randomness — not needed because iOS caches the result all day
- Pagination — batch size is caller-controlled via `count` param (max 10 in current usage)

## Decisions

### 1. Flat `Affirmation` model — no relations, auto-increment ID

Affirmations have no natural unique ID in the JSON (they're just `{ quote, category }`). An auto-increment integer primary key is the simplest approach.

```prisma
model Affirmation {
  id       Int    @id @default(autoincrement())
  quote    String
  category String
}
```

*Alternatives considered:* UUID generated from quote hash — adds complexity for no benefit; using quote as primary key — quotes can be long and aren't guaranteed unique.

### 2. `createMany` for seeding — not upsert loop

27,000 individual upserts would take minutes. `prisma.affirmation.createMany({ data: [...] })` inserts all rows in a single SQL statement, completing in seconds. Since affirmations have no natural ID, upsert isn't applicable — we just check count > 0 and skip if already seeded.

```typescript
await prisma.affirmation.createMany({ data: sessions })
```

*Alternatives considered:* Chunked batches of 1,000 — not needed; SQLite handles a 27k createMany fine.

### 3. Random batch via TypeScript shuffle — not SQL `ORDER BY RANDOM()`

Prisma doesn't support `ORDER BY RANDOM()` in its query API directly. Options:
- Raw SQL query: `SELECT * FROM Affirmation WHERE category IN (...) ORDER BY RANDOM() LIMIT count` — works but bypasses Prisma's type safety
- Fetch all matching rows, shuffle in TypeScript, return first `count`

With ~27,000 affirmations across 6 categories, a filter for 2 categories returns ~9,000 rows. Fetching 9,000 small rows from SQLite and shuffling in TypeScript takes ~10ms — acceptable. This keeps all logic in typed TypeScript.

*Alternatives considered:* Raw SQL — works but is less readable; fetching a fixed overcount (e.g. `count * 10`) and shuffling — fragile if categories have fewer rows than expected.

### 4. Multi-category filter uses Prisma `in` operator

```typescript
prisma.affirmation.findMany({
  where: { category: { in: categories } }
})
```

`categories` is parsed from `?categories=confidence,mindfulness` by splitting on comma. An empty or missing `categories` param returns HTTP 400 — a batch without any category filter makes no sense.

### 5. `AffirmationService` keeps the same public interface — only internals change

`generateBatch(count:for:useAppleIntelligence:)` signature is unchanged. When `useAppleIntelligence = false`, instead of calling `loadStaticBatch`, it calls `networkClient.get(path)`. The `HomeViewModel` call site is completely unaffected.

The network path is:
```swift
let categoryParams = categories.map(\.rawValue).joined(separator: ",")
let path = "/api/affirmations/batch?categories=\(categoryParams)&count=\(count)"
let pairs: [CachedAffirmation] = try await networkClient.get(path)
```

`CachedAffirmation` is already `Codable` and matches the response shape `[{ quote, category }]` — no new model needed.

*Alternatives considered:* New `AffirmationBatchItem` response model — unnecessary since `CachedAffirmation` already has the right shape.

### 6. `affirmationService` wired with `networkClient` via constructor injection

Matches the pattern established in Phase 1 (ArticlesService) and Phase 2 (MeditationService).

```swift
// Container+App.swift
var affirmationService: Factory<AffirmationServiceProtocol> {
    self { @MainActor in AffirmationService(networkClient: self.networkClient()) }.singleton
}
```

## Risks / Trade-offs

**[Risk] 27k-row createMany may time out in Docker on first seed** → SQLite handles bulk inserts well; 27k rows with two small string columns should complete in under 2 seconds. The skip-if-exists guard means it only runs once.

**[Risk] Fetching ~9,000 rows per request for TypeScript shuffle** → Each affirmation row is small (quote string + category string). At ~200 bytes average, 9,000 rows ≈ 1.8 MB in memory — fine for a local dev server. For future scaling, a raw SQL `ORDER BY RANDOM()` approach could replace this.

**[Risk] `CachedAffirmation.category` decodes as `AffirmationCategory` enum** → The backend returns `category` as a raw string (e.g. `"confidence"`). `CachedAffirmation` decodes it as `AffirmationCategory` via `Codable`. As long as the backend strings match the Swift enum raw values exactly, this works. The seed script reads from the same `affirmations.json` the iOS app used — raw values are identical.

## Migration Plan

1. Add `Affirmation` model to `prisma/schema.prisma`
2. Run `npx prisma migrate dev --name add-affirmations` locally
3. Extend `prisma/seed.ts` with `createMany` affirmation seeding
4. Run `npx prisma db seed` — verify ~27,000 rows inserted
5. Create `src/routes/affirmations.ts` and mount in `src/index.ts`
6. Rebuild Docker: `docker compose up --build`
7. Verify endpoint with curl
8. Update `AffirmationService.swift` — add constructor, replace static path with network call
9. Update `Container+App.swift` — wire `networkClient`
10. Delete `affirmations.json` from iOS bundle
11. Build iOS: `xcodebuild ... build 2>&1 | tail -20`
