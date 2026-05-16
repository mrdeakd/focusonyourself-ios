## ADDED Requirements

### Requirement: NarrationEntry model exists in the database
The backend SHALL define a Prisma `NarrationEntry` model with `id Int @id @default(autoincrement())`, `instruction String @unique`, and `audioUrl String`.

#### Scenario: Migration creates table
- **WHEN** `npx prisma migrate deploy` is run against a fresh database
- **THEN** the `NarrationEntry` table is created with `id`, `instruction`, and `audioUrl` columns

### Requirement: NarrationEntry rows are seeded from narration_map.json
The seed script SHALL read `prisma/narration_map.json`, prepend `SUPABASE_AUDIO_URL` to each filename (appending `.mp3`), and insert all entries via `createMany`. Seeding SHALL be idempotent — if any entries already exist, the seed SHALL skip.

#### Scenario: Fresh database is seeded
- **WHEN** `npx prisma db seed` is run on an empty database
- **THEN** all narration entries are inserted with full Supabase URLs as `audioUrl`

#### Scenario: audioUrl contains the full Supabase URL
- **WHEN** the seed runs
- **THEN** each `audioUrl` value starts with the value of `SUPABASE_AUDIO_URL` and ends with `.mp3`

#### Scenario: Seeding is idempotent
- **WHEN** `npx prisma db seed` is run a second time
- **THEN** the `NarrationEntry` count is unchanged

### Requirement: GET /api/narration-map returns instruction-to-URL map
The backend SHALL expose `GET /api/narration-map` returning a JSON object where each key is an instruction string and each value is its full audio URL. The response shape SHALL be `{ [instruction: string]: string }`.

#### Scenario: Endpoint returns all entries as a map
- **WHEN** a client sends `GET /api/narration-map`
- **THEN** the response is HTTP 200 with a JSON object mapping all instruction strings to their Supabase audio URLs

#### Scenario: All values are full URLs
- **WHEN** a client sends `GET /api/narration-map`
- **THEN** every value in the response starts with `https://` and ends with `.mp3`

### Requirement: SUPABASE_AUDIO_URL is the only place the CDN host is defined
The Supabase base URL SHALL be read from the `SUPABASE_AUDIO_URL` environment variable at seed time. No hardcoded CDN host SHALL appear in source code.

#### Scenario: Changing the CDN requires no code change
- **WHEN** `SUPABASE_AUDIO_URL` is updated to a different CDN host and the database is reseeded
- **THEN** the endpoint returns URLs pointing to the new host with no code changes
