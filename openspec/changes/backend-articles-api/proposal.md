## Why

All app content (articles, meditations, affirmations, audio) is bundled inside the iOS app, meaning any content update requires a full App Store release. This change extracts the Articles resource to a local Node.js backend as Phase 1 of a phased migration — delivering the first working API, establishing the backend project structure, and building Node.js skills along the way.

## What Changes

- **New project** `focusonyourself_backend/` (sibling to the iOS project) — Node.js + TypeScript, Express.js, Prisma ORM, SQLite database, containerised with Docker (`Dockerfile` + `docker-compose.yml`)
- **New endpoint** `GET /api/articles/daily?date=YYYY-MM-DD` — returns 4 deterministically selected articles using a date-seeded shuffle (same logic as the current iOS implementation)
- **New file** `focusonyourself_backend/LEARN.md` — living teaching doc covering tools, config, commands, and how everything connects
- **iOS: remove** unused `allArticles()` and `articles(for:)` methods from `ArticlesServiceProtocol` and `ArticlesService` (never called anywhere in the app)
- **iOS: add** `NetworkClient` — thin `URLSession` async/await wrapper for API calls
- **iOS: replace** `ArticlesService` bundle-JSON loading with a network call to the new endpoint

## Capabilities

### New Capabilities

- `articles-api`: Backend REST endpoint that seeds articles from `articles.json` into SQLite and serves a deterministic daily batch of 4 articles via `GET /api/articles/daily`
- `ios-network-client`: iOS `NetworkClient` abstraction that wraps `URLSession` async/await and is used by `ArticlesService` to fetch from the backend

### Modified Capabilities

- `articles-service`: Existing iOS `ArticlesService` and `ArticlesServiceProtocol` — requirements change from bundle-based loading to network-based loading; unused methods removed

## Impact

**New project:**
- `/Users/deakdavid/Work/ideas/focusonyourself_backend/` (new directory)

**iOS files modified:**
- `FocusOnYourself/Services/ArticlesServiceProtocol.swift` — remove 2 unused method declarations
- `FocusOnYourself/Services/ArticlesService.swift` — remove unused methods, replace bundle load with network call
- `FocusOnYourself/Services/NetworkClient.swift` — new file

**No changes to:**
- `HomeViewModel` — interface unchanged (still calls `dailyArticles()`)
- Paywall / Pro gating — stays on iOS
- Other resource types (meditations, affirmations, audio) — Phase 2+
- iCloud / UserDefaults persistence — unaffected
