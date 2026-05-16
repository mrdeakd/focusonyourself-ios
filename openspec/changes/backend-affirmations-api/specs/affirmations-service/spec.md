## MODIFIED Requirements

### Requirement: generateBatch fetches from backend when not using Apple Intelligence
`AffirmationService.generateBatch(count:for:useAppleIntelligence:)` SHALL call `networkClient.get("/api/affirmations/batch?categories=<csv>&count=<n>")` when `useAppleIntelligence` is `false`, decoding the response as `[CachedAffirmation]` and mapping to the tuple return type. The Apple Intelligence path SHALL remain unchanged. The method signature SHALL remain unchanged.

#### Scenario: Static path calls backend
- **WHEN** `generateBatch(count: 10, for: [.confidence, .mindfulness], useAppleIntelligence: false)` is called and the backend returns 10 affirmations
- **THEN** the method returns 10 `(quote, category)` tuples without reading from the bundle

#### Scenario: Apple Intelligence path is unchanged
- **WHEN** `generateBatch(count: 10, for: [.confidence], useAppleIntelligence: true)` is called
- **THEN** the method uses `LanguageModelSession` and does not call the network client

#### Scenario: Backend unreachable
- **WHEN** `generateBatch` is called with `useAppleIntelligence: false` and no server is running
- **THEN** the method throws a network error (caller handles via existing error path)

### Requirement: AffirmationService receives networkClient via constructor
`AffirmationService` SHALL accept a `networkClient: NetworkClientProtocol` constructor parameter, registered in `Container+App.swift` with `self.networkClient()`. The `@Observable @MainActor` class attributes SHALL be preserved.

#### Scenario: DI container wires networkClient
- **WHEN** the app launches and the DI container initialises `affirmationService`
- **THEN** it passes `self.networkClient()` to the `AffirmationService` initialiser

## REMOVED Requirements

### Requirement: AffirmationService loads affirmations from the app bundle
**Reason**: Replaced by backend API fetch. The 3.5 MB `affirmations.json` bundle asset is deleted.
**Migration**: Affirmations are now served by `GET /api/affirmations/batch`. The `loadStaticAffirmations()`, `loadStaticBatch()`, `staticAffirmations` cache property, and `AffirmationServiceError.datasetNotFound` are removed.
