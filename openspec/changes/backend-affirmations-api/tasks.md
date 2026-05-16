## 1. Backend — Prisma Schema

- [x] 1.1 Add `Affirmation` model to `prisma/schema.prisma`: `id Int @id @default(autoincrement())`, `quote String`, `category String`
- [x] 1.2 Run `DATABASE_URL="file:./prisma/dev.db" npx prisma migrate dev --name add-affirmations` to generate migration SQL and apply it locally
- [x] 1.3 Run `DATABASE_URL="file:./prisma/dev.db" npx prisma generate` to regenerate Prisma client with the new model

## 2. Backend — Seed

- [x] 2.1 Copy `affirmations.json` from iOS bundle (`FocusOnYourself/Resources/affirmations.json`) to `focusonyourself_backend/prisma/affirmations.json`
- [x] 2.2 Add `seedAffirmations()` to `prisma/seed.ts` — check `prisma.affirmation.count() > 0` and skip; otherwise read `affirmations.json` via `process.cwd()` path and call `prisma.affirmation.createMany({ data: [...] })`
- [x] 2.3 Call `seedAffirmations()` from `main()` alongside existing seed functions
- [x] 2.4 Build: `npm run build`
- [x] 2.5 Run `DATABASE_URL="file:./prisma/dev.db" npx prisma db seed` and verify ~27,000 rows inserted
- [x] 2.6 Run seed a second time and confirm count is unchanged (idempotent)

## 3. Backend — Affirmations Endpoint

- [x] 3.1 Create `src/routes/affirmations.ts` with `GET /batch` route handler
- [x] 3.2 Define valid categories array: `['confidence', 'health', 'relationships', 'mindfulness', 'career', 'resilience']`
- [x] 3.3 Parse `?categories=` by splitting on comma; return HTTP 400 if missing, empty, or contains any unknown value
- [x] 3.4 Parse `?count=` as integer; return HTTP 400 if missing, zero, or non-numeric
- [x] 3.5 Query `prisma.affirmation.findMany({ where: { category: { in: categories } } })`, shuffle result in TypeScript using `seedrandom` or `Array.sort(() => Math.random() - 0.5)`, return first `count` items
- [x] 3.6 Mount the affirmations router in `src/index.ts` at `/api/affirmations`
- [x] 3.7 Rebuild Docker: `docker compose up --build`
- [x] 3.8 Verify: `curl "localhost:3005/api/affirmations/batch?categories=confidence,mindfulness&count=10"` returns 10 objects with `quote` and `category`
- [x] 3.9 Verify: all returned `category` values are from the requested categories
- [x] 3.10 Verify: `curl "localhost:3005/api/affirmations/batch?count=10"` returns HTTP 400
- [x] 3.11 Verify: `curl "localhost:3005/api/affirmations/batch?categories=confidence,unknown&count=10"` returns HTTP 400
- [x] 3.12 Verify: `curl "localhost:3005/api/affirmations/batch?categories=confidence"` (no count) returns HTTP 400

## 4. iOS — AffirmationService Rewrite

- [x] 4.1 Add `private let networkClient: NetworkClientProtocol` property to `AffirmationService`
- [x] 4.2 Add `init(networkClient: NetworkClientProtocol)` to `AffirmationService`
- [x] 4.3 Remove `@ObservationIgnored private var staticAffirmations` cache property
- [x] 4.4 Remove `loadStaticAffirmations()` private method
- [x] 4.5 Remove `loadStaticBatch(count:categories:)` private method
- [x] 4.6 Remove `AffirmationServiceError` enum
- [x] 4.7 Replace the `else` branch of `generateBatch` (the `loadStaticBatch` call) with a network call: build path `/api/affirmations/batch?categories=<csv>&count=<n>`, call `networkClient.get(path)` as `[CachedAffirmation]`, map to tuple array
- [x] 4.8 Update `affirmationService` registration in `Container+App.swift` to pass `self.networkClient()`
- [x] 4.9 Build the iOS project — no compilation errors

## 5. iOS — Cleanup

- [x] 5.1 Delete `FocusOnYourself/Resources/affirmations.json` from the iOS project (−3.5 MB)
- [x] 5.2 Build the iOS project — no compilation errors
- [ ] 5.3 Run the app in Simulator with backend running — affirmations carousel loads 10 quotes on home screen
- [ ] 5.4 Verify Apple Intelligence path still works if enabled (Pro + iOS 18)
