## ADDED Requirements

### Requirement: Affirmation model exists in the database
The backend SHALL define a Prisma `Affirmation` model with `id Int @id @default(autoincrement())`, `quote String`, and `category String`. The model is flat with no relations.

#### Scenario: Migration runs cleanly
- **WHEN** `npx prisma migrate deploy` is run against a fresh database
- **THEN** the `Affirmation` table is created with `id`, `quote`, and `category` columns

### Requirement: Affirmations are seeded from affirmations.json
The seed script SHALL insert all ~27,000 affirmations from `prisma/affirmations.json` using `createMany` in a single operation. Seeding SHALL be idempotent — if any affirmations already exist, the seed SHALL skip without inserting duplicates.

#### Scenario: Fresh database is seeded
- **WHEN** `npx prisma db seed` is run on an empty database
- **THEN** approximately 27,000 `Affirmation` rows are inserted

#### Scenario: Seeding is idempotent
- **WHEN** `npx prisma db seed` is run a second time
- **THEN** the affirmation count remains unchanged

### Requirement: GET /api/affirmations/batch returns a random selection
The backend SHALL expose `GET /api/affirmations/batch?categories=<csv>&count=<n>` returning a JSON array of `count` affirmation objects, each with `quote` (String) and `category` (String). The selection SHALL be random — different requests with the same parameters MAY return different results.

#### Scenario: Valid request returns correct count
- **WHEN** a client sends `GET /api/affirmations/batch?categories=confidence,mindfulness&count=10`
- **THEN** the response is HTTP 200 with a JSON array of exactly 10 objects each having `quote` and `category`

#### Scenario: Returned categories match the filter
- **WHEN** a client sends `GET /api/affirmations/batch?categories=confidence&count=5`
- **THEN** all 5 returned affirmations have `category` equal to `"confidence"`

#### Scenario: Multi-category request spans categories
- **WHEN** a client sends `GET /api/affirmations/batch?categories=confidence,mindfulness&count=10`
- **THEN** returned affirmations have `category` values from only `confidence` and `mindfulness`

### Requirement: Missing or empty categories returns 400
The `categories` parameter is required. An absent or empty `categories` value SHALL return HTTP 400 with an error message.

#### Scenario: Missing categories param
- **WHEN** a client sends `GET /api/affirmations/batch?count=10` with no `categories`
- **THEN** the response is HTTP 400

#### Scenario: Empty categories param
- **WHEN** a client sends `GET /api/affirmations/batch?categories=&count=10`
- **THEN** the response is HTTP 400

### Requirement: Invalid category value returns 400
Any `categories` value that is not one of `confidence`, `health`, `relationships`, `mindfulness`, `career`, `resilience` SHALL cause the request to return HTTP 400 with an error message listing valid values.

#### Scenario: Unknown category rejected
- **WHEN** a client sends `GET /api/affirmations/batch?categories=confidence,unknown&count=10`
- **THEN** the response is HTTP 400

### Requirement: Missing or invalid count returns 400
The `count` parameter is required and must be a positive integer. An absent, zero, or non-numeric value SHALL return HTTP 400.

#### Scenario: Missing count param
- **WHEN** a client sends `GET /api/affirmations/batch?categories=confidence` with no `count`
- **THEN** the response is HTTP 400

#### Scenario: Invalid count value
- **WHEN** a client sends `GET /api/affirmations/batch?categories=confidence&count=abc`
- **THEN** the response is HTTP 400
