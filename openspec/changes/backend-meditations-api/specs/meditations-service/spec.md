## MODIFIED Requirements

### Requirement: MeditationServiceProtocol exposes only sessions(for:) as async throws
`MeditationServiceProtocol` SHALL declare exactly one method: `func sessions(for category: MeditationCategory?) async throws -> [MeditationSession]`. The method `allSessions()` SHALL be removed from the protocol as it has no callers.

#### Scenario: Protocol has one method
- **WHEN** a type conforms to `MeditationServiceProtocol`
- **THEN** it is only required to implement `sessions(for:) async throws -> [MeditationSession]`

### Requirement: sessions(for:) fetches from the backend API
`MeditationService.sessions(for:)` SHALL fetch sessions from `GET /api/meditations` (with optional `?category=<value>` appended when category is non-nil) using `NetworkClientProtocol`, decode the response as `[MeditationSession]`, and return it. It SHALL NOT read from the app bundle.

#### Scenario: Fetching without category filter
- **WHEN** `sessions(for: nil)` is called and the backend returns all sessions
- **THEN** the method returns all `MeditationSession` values

#### Scenario: Fetching with category filter
- **WHEN** `sessions(for: .morning)` is called
- **THEN** the request is sent to `/api/meditations?category=morning` and only morning sessions are returned

#### Scenario: Backend is unreachable
- **WHEN** `sessions(for:)` is called and no server is running
- **THEN** the method throws an error (caller is responsible for handling the empty state)

## REMOVED Requirements

### Requirement: MeditationService loads sessions from the app bundle
**Reason**: Replaced by backend API fetch. Bundle-based loading is no longer needed for meditations.
**Migration**: Sessions are now served by `GET /api/meditations`. The `meditations.json` bundle file is deleted from the iOS project.

### Requirement: MeditationServiceProtocol exposes allSessions()
**Reason**: This method has no callers anywhere in the app and is being removed to reduce dead surface area.
**Migration**: No migration needed — nothing calls this method.
