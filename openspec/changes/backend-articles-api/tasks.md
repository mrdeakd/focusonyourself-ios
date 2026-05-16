## 1. Backend Project Setup

- [x] 1.1 Create `focusonyourself_backend/` directory next to the iOS project
- [x] 1.2 Run `npm init -y` and install dependencies: `express`, `@prisma/client`, `seedrandom`
- [x] 1.3 Install dev dependencies: `typescript`, `ts-node-dev`, `@types/express`, `@types/node`, `@types/seedrandom`, `prisma`
- [x] 1.4 Create `tsconfig.json` with `target: ES2020`, `module: CommonJS`, `outDir: dist`, `strict: true`
- [x] 1.5 Add npm scripts to `package.json`: `dev` (ts-node-dev), `build` (tsc), `seed`

## 2. Docker Setup

- [x] 2.1 Create `Dockerfile` — Node 20 Alpine base, copy source, install deps, build TypeScript, expose port 3000
- [x] 2.2 Create `docker-compose.yml` — service `api`, build from `Dockerfile`, port `3000:3000`, named volume `db-data` mounted at `/app/prisma`
- [x] 2.3 Add `.dockerignore` — exclude `node_modules`, `dist`, `.env`, `prisma/*.db`
- [ ] 2.4 Verify `docker compose up` builds successfully and container appears in Docker Desktop

## 3. Database — Prisma + SQLite

- [x] 3.1 Run `npx prisma init --datasource-provider sqlite` to create `prisma/schema.prisma` and `.env`
- [x] 3.2 Define `Article` model in `schema.prisma`: `id String @id`, `title String`, `topic String`, `readTimeMinutes Int`, `body String`
- [x] 3.3 Run `npx prisma migrate dev --name init` to create the SQLite database and apply the migration
- [x] 3.4 Write `prisma/seed.ts` — reads `articles.json`, upserts each article by `id` (idempotent: no duplicates on re-run)
- [x] 3.5 Add `"prisma": { "seed": "ts-node prisma/seed.ts" }` to `package.json`
- [x] 3.6 Run `npx prisma db seed` and verify 40 rows in the database via `npx prisma studio`

## 4. Articles API Endpoint

- [x] 4.1 Create `src/index.ts` — Express app, mount router, listen on port 3000
- [x] 4.2 Create `src/routes/articles.ts` — `GET /api/articles/daily` route handler
- [x] 4.3 Implement date validation: reject non-`YYYY-MM-DD` values with HTTP 400
- [x] 4.4 Implement the seed algorithm to match Swift exactly — DJB2 hash over the date string (`seed = chars.reduce(5381n, (acc, c) => (acc * 31n + BigInt(c.charCodeAt(0))) & 0xFFFFFFFFFFFFFFFFn)`), then xorshift-64 RNG (shifts 13, 7, 17) used for Fisher-Yates shuffle, return first 4
- [x] 4.5 Query all articles from Prisma, apply shuffle, return JSON array
- [x] 4.6 Verify with curl: `curl "localhost:3000/api/articles/daily?date=2026-05-16"` returns 4 articles
- [x] 4.7 Verify same date always returns same 4 articles (run curl twice, compare output)
- [x] 4.8 Verify different dates return different sets

## 5. LEARN.md

- [x] 5.1 Write "What is…" section — one paragraph each for Node.js, TypeScript, Express, Prisma, SQLite, Docker
- [x] 5.2 Write "Why we chose it" section — brief rationale for each tool vs alternatives
- [x] 5.3 Write "Project structure" section — annotated file tree explaining each file's role
- [x] 5.4 Write "Key config files" section — annotated excerpts of `package.json`, `tsconfig.json`, `schema.prisma`, `docker-compose.yml`, `.env`
- [x] 5.5 Write "Commands reference" section — every command used, what it does, when to run it
- [x] 5.6 Write "How the endpoint works" section — request lifecycle: Express router → date validation → Prisma query → seeded shuffle → JSON response
- [x] 5.7 Write "How iOS connects" section — Networking layer, URLSession, why localhost HTTP works without ATS changes

## 6. iOS — Remove Unused Methods

- [x] 6.1 Remove `allArticles()` declaration from `ArticlesServiceProtocol.swift`
- [x] 6.2 Remove `articles(for:)` declaration from `ArticlesServiceProtocol.swift`
- [x] 6.3 Remove `allArticles()` implementation from `ArticlesService.swift`
- [x] 6.4 Remove `articles(for:)` implementation from `ArticlesService.swift`
- [x] 6.5 Remove `SeededRNG` and `dateHash` private helpers from `ArticlesService.swift` (replaced by backend)
- [x] 6.6 Build the iOS project and confirm no compilation errors

## 7. iOS — Networking Layer

- [x] 7.1 Create `FocusOnYourself/Networking/` group in Xcode
- [x] 7.2 Create `NetworkError.swift` — enum with cases `invalidURL` and `badResponse(Int)`
- [x] 7.3 Create `NetworkClientProtocol.swift` — protocol with `func get<T: Decodable>(_ path: String) async throws -> T`
- [x] 7.4 Create `URLSessionNetworkClient.swift` — struct conforming to `NetworkClientProtocol`, `baseURL = URL(string: "http://localhost:3000")!`, builds full URL from `baseURL + path`, calls `URLSession.shared.data(from:)`, throws `NetworkError.badResponse` on non-200
- [x] 7.5 Register `networkClient: Factory<NetworkClientProtocol>` in `Container+App.swift` as a singleton returning `URLSessionNetworkClient`
- [x] 7.6 Build the iOS project — no compilation errors

## 8. iOS — ArticlesService Network Swap

- [x] 8.1 Make `dailyArticles()` in `ArticlesServiceProtocol` `async throws`
- [x] 8.2 Add `networkClient: NetworkClientProtocol` constructor parameter to `ArticlesService`
- [x] 8.3 Update `articlesService` registration in `Container+App.swift` to pass `self.networkClient()`
- [x] 8.4 Replace bundle-loading body of `ArticlesService.dailyArticles()` with `try await networkClient.get("/api/articles/daily?date=\(today)")` where `today` is formatted as `yyyy-MM-dd`
- [x] 8.5 Update `HomeViewModel` to call `dailyArticles()` inside a `Task` with `try await` and handle thrown errors (show empty articles array on failure)
- [x] 8.6 Build the iOS project — no compilation errors
- [ ] 8.7 Run the app in Simulator with backend running — articles section loads correctly
- [ ] 8.8 Run the app in Simulator with backend stopped — articles section shows empty/error state gracefully
