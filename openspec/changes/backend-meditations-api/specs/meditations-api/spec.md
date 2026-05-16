## ADDED Requirements

### Requirement: MeditationSession and MeditationStep models exist in the database
The backend SHALL define two Prisma models: `MeditationSession` (with `id`, `title`, `category`, `durationMinutes`, `isPro`) and `MeditationStep` (with `id`, `order`, `instruction?`, `silenceDurationSeconds?`, `sessionId`). `MeditationStep` SHALL have a many-to-one relation to `MeditationSession` via `sessionId`.

#### Scenario: Schema migration runs cleanly
- **WHEN** `npx prisma migrate deploy` is run against a fresh database
- **THEN** both `MeditationSession` and `MeditationStep` tables are created with all columns

### Requirement: Meditation sessions are seeded from meditations.json
The seed script SHALL populate `MeditationSession` and `MeditationStep` rows from `prisma/meditations.json`. Each step SHALL be assigned an `order` value equal to its index in the JSON array. Seeding SHALL be idempotent — if sessions already exist, the seed SHALL skip without inserting duplicates.

#### Scenario: Fresh database is seeded
- **WHEN** `npx prisma db seed` is run on an empty database
- **THEN** 24 `MeditationSession` rows and all their associated `MeditationStep` rows are inserted

#### Scenario: Seeding is idempotent
- **WHEN** `npx prisma db seed` is run a second time
- **THEN** the session and step counts remain unchanged (no duplicates)

### Requirement: GET /api/meditations returns all sessions with nested steps
The backend SHALL expose `GET /api/meditations` returning a JSON array of all meditation sessions. Each session object SHALL include `id`, `title`, `category`, `durationMinutes`, `isPro`, and a `steps` array. Each step SHALL include `order`, `instruction` (nullable), and `silenceDurationSeconds` (nullable). Steps SHALL be ordered by `order` ascending.

#### Scenario: All sessions returned
- **WHEN** a client sends `GET /api/meditations`
- **THEN** the response is HTTP 200 with a JSON array of 24 session objects each containing a `steps` array

#### Scenario: Steps are in correct order
- **WHEN** a client sends `GET /api/meditations`
- **THEN** each session's `steps` array is ordered by `order` ascending, matching the original JSON array order

### Requirement: GET /api/meditations?category= filters by category
The backend SHALL filter sessions by `category` when a `?category=` query parameter is provided. Valid values are `morning`, `focus`, `anxiety`, and `sleep`. An invalid category value SHALL return HTTP 400.

#### Scenario: Valid category filter
- **WHEN** a client sends `GET /api/meditations?category=morning`
- **THEN** the response is HTTP 200 with only sessions whose category is `morning`

#### Scenario: No category returns all sessions
- **WHEN** a client sends `GET /api/meditations` with no query parameters
- **THEN** the response is HTTP 200 with all 24 sessions

#### Scenario: Invalid category returns 400
- **WHEN** a client sends `GET /api/meditations?category=invalid`
- **THEN** the response is HTTP 400 with an error message listing valid values
