## Why

The iOS app bundles ~27,000 affirmations in `affirmations.json` (3.5 MB) — the largest bundled asset in the app. Phase 3 moves the static affirmation dataset to the backend, shrinking the app by 3.5 MB and eliminating bundle loading. The Apple Intelligence path (on-device AI generation) is entirely unaffected and stays on-device.

## What Changes

- **Backend: new Prisma model** `Affirmation` with `id`, `quote`, `category` — flat, no relations
- **Backend: seed** ~27,000 affirmations from `affirmations.json` using `createMany` for performance
- **Backend: new endpoint** `GET /api/affirmations/batch?categories=confidence,mindfulness&count=10` — returns a random selection of `count` affirmations filtered across the given categories
- **iOS: replace** the static bundle-loading path in `AffirmationService.generateBatch` with a network call when `useAppleIntelligence = false`
- **iOS: remove** `loadStaticAffirmations()`, `loadStaticBatch()`, `staticAffirmations` cache property, and `AffirmationServiceError.datasetNotFound`
- **iOS: add** `networkClient: NetworkClientProtocol` constructor parameter to `AffirmationService`
- **iOS: remove** `affirmations.json` from the app bundle (−3.5 MB)

**Unchanged:**
- `cachedBatch()` and `cacheBatch()` — UserDefaults daily caching stays entirely on iOS
- Apple Intelligence path (`generateWithAppleIntelligence`) — stays on-device, untouched
- `AffirmationServiceProtocol` interface — `generateBatch`, `cachedBatch`, `cacheBatch` signatures unchanged
- Pro/Free category gating — enforced on iOS, backend returns all categories freely

## Capabilities

### New Capabilities

- `affirmations-api`: Backend endpoint `GET /api/affirmations/batch` serving a random batch of affirmations filtered by one or more categories and a requested count; Prisma `Affirmation` model; seed from `affirmations.json` using `createMany`

### Modified Capabilities

- `affirmations-service`: `AffirmationService` — static bundle-loading path replaced by network call; `networkClient` injected via constructor; Apple Intelligence path and caching logic unchanged

## Impact

**Backend files modified:**
- `prisma/schema.prisma` — add `Affirmation` model
- `prisma/seed.ts` — add affirmation seeding with `createMany`
- `src/routes/affirmations.ts` — new route file
- `src/index.ts` — mount affirmations router

**iOS files modified:**
- `FocusOnYourself/Services/AffirmationService.swift` — replace static path with network call, remove helpers
- `FocusOnYourself/App/Container+App.swift` — wire `networkClient` into `affirmationService`

**iOS files deleted:**
- `FocusOnYourself/Resources/affirmations.json` (−3.5 MB)

**No changes to:**
- `AffirmationServiceProtocol.swift`
- `HomeViewModel.swift`
- `AffirmationsCarouselView.swift`
- `CachedAffirmation.swift` / `StaticAffirmation.swift` models
