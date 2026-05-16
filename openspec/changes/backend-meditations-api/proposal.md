## Why

Meditation sessions are currently bundled inside the iOS app as `meditations.json`. Phase 2 of the backend migration extracts them to the Node.js backend — removing another bundled asset, introducing a new Prisma concept (one-to-many relations between sessions and steps), and teaching how to handle nested data in a REST API.

## What Changes

- **Backend: new Prisma models** `MeditationSession` and `MeditationStep` with a one-to-many relation — sessions have many ordered steps
- **Backend: seed** `meditations.json` into SQLite via the existing seed pipeline
- **Backend: new endpoint** `GET /api/meditations?category=morning` — returns all sessions with nested steps, optionally filtered by category
- **iOS: remove** unused `allSessions()` from `MeditationServiceProtocol` and `MeditationService`
- **iOS: add** `NetworkClient` call to `MeditationService`, replacing `Bundle.decodeJSON`
- **iOS: update** `MeditateViewModel` — `filteredSessions` changes from a synchronous computed property to a stored property loaded via async `loadSessions()`
- **iOS: remove** `meditations.json` from the app bundle

## Capabilities

### New Capabilities

- `meditations-api`: Backend endpoint `GET /api/meditations?category=<category>` serving sessions with nested steps; Prisma schema with `MeditationSession → MeditationStep` relation; seed from `meditations.json`

### Modified Capabilities

- `meditations-service`: `MeditationServiceProtocol` and `MeditationService` — protocol shrinks to one `async throws` method; bundle loading replaced by network call
- `ios-network-client`: No code changes — `NetworkClient` is reused as-is; `MeditationService` becomes the second caller

## Impact

**Backend files modified:**
- `prisma/schema.prisma` — add `MeditationSession` and `MeditationStep` models
- `prisma/seed.ts` — add meditation seeding from `meditations.json`
- `src/routes/meditations.ts` — new route file
- `src/index.ts` — mount meditations router

**iOS files modified:**
- `FocusOnYourself/Services/MeditationServiceProtocol.swift` — remove `allSessions()`, make `sessions(for:)` async throws
- `FocusOnYourself/Services/MeditationService.swift` — replace bundle load with network call, add networkClient constructor parameter
- `FocusOnYourself/Features/Meditate/MeditateViewModel.swift` — `filteredSessions` becomes stored property, add `loadSessions()` async method
- `FocusOnYourself/App/Container+App.swift` — wire `networkClient` into `meditationService`

**iOS files deleted:**
- `FocusOnYourself/Resources/meditations.json`

**No changes to:**
- `MeditationAudioService` — audio playback unchanged
- `MeditationPlayerViewModel` — receives `MeditationSession` as before, no networking
- Pro/Free gating — `isPro` flag stays on iOS
