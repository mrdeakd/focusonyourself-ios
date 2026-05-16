## ADDED Requirements

### Requirement: Backend project exists and runs via Docker
The backend SHALL be a Node.js + TypeScript project located at `focusonyourself_backend/` (sibling to the iOS project). It SHALL be containerised with Docker and runnable via `docker compose up` with no additional setup beyond having Docker installed. The SQLite database file SHALL be persisted via a Docker volume so data survives container restarts.

#### Scenario: Developer starts the backend
- **WHEN** the developer runs `docker compose up` inside `focusonyourself_backend/`
- **THEN** the container builds, migrations run, the seed script executes, and the server listens on `http://localhost:3000`

#### Scenario: Data persists across restarts
- **WHEN** the developer stops the container with `docker compose down` and starts it again
- **THEN** previously seeded articles are still present in the database

### Requirement: Articles are stored in SQLite via Prisma
The backend SHALL use a Prisma-managed SQLite database with an `Article` model that stores all fields from `articles.json`. A seed script SHALL populate the database from the bundled `articles.json` file.

#### Scenario: Developer seeds the database
- **WHEN** the developer runs `npm run seed`
- **THEN** all articles from `articles.json` are inserted into the SQLite database with no duplicates

#### Scenario: Seeding is idempotent
- **WHEN** the developer runs `npm run seed` a second time
- **THEN** the database contains the same number of articles as after the first seed (no duplicates created)


### Requirement: Daily articles endpoint returns 4 articles
The backend SHALL expose `GET /api/articles/daily` that returns exactly 4 articles as a JSON array. Each article object SHALL include `id`, `title`, `topic`, `readTimeMinutes`, and `body`.

#### Scenario: Request with explicit date
- **WHEN** a client sends `GET /api/articles/daily?date=2026-05-16`
- **THEN** the response is HTTP 200 with a JSON array of exactly 4 article objects

#### Scenario: Request without date parameter
- **WHEN** a client sends `GET /api/articles/daily` with no query parameters
- **THEN** the response is HTTP 200 using today's UTC date as the seed

#### Scenario: Invalid date parameter
- **WHEN** a client sends `GET /api/articles/daily?date=not-a-date`
- **THEN** the response is HTTP 400 with an error message

### Requirement: Daily rotation is deterministic by date
The same `date` value SHALL always produce the same 4 articles. Different `date` values SHALL produce different orderings (with high probability). The shuffle algorithm SHALL be a seeded Fisher-Yates using a hash of the date string as the seed.

#### Scenario: Same date returns same articles
- **WHEN** two requests are made with the same `date` parameter
- **THEN** both responses contain the identical 4 articles in the identical order

#### Scenario: Different dates return different articles
- **WHEN** two requests are made with different `date` parameters
- **THEN** the returned article sets differ (at least one article is different)
