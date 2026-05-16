## MODIFIED Requirements

### Requirement: ArticlesServiceProtocol exposes only dailyArticles
`ArticlesServiceProtocol` SHALL declare exactly one method: `func dailyArticles() async throws -> [Article]`. The methods `allArticles()` and `articles(for:)` SHALL be removed from the protocol as they have no callers.

#### Scenario: Protocol has one method
- **WHEN** a type conforms to `ArticlesServiceProtocol`
- **THEN** it is only required to implement `dailyArticles() async throws -> [Article]`

### Requirement: dailyArticles fetches from the backend API
`ArticlesService.dailyArticles()` SHALL fetch articles from `GET /api/articles/daily?date=<today>` using `NetworkClient`, decode the response as `[Article]`, and return it. It SHALL NOT read from the app bundle.

#### Scenario: Backend is reachable
- **WHEN** `dailyArticles()` is called and the backend returns 4 articles
- **THEN** the method returns those 4 `Article` values

#### Scenario: Backend is unreachable
- **WHEN** `dailyArticles()` is called and no server is running at `localhost:3000`
- **THEN** the method throws an error (caller is responsible for handling the empty state)

## REMOVED Requirements

### Requirement: ArticlesService loads articles from the app bundle
**Reason**: Replaced by backend API fetch. Bundle-based loading is no longer needed for articles.
**Migration**: Articles are now served by `GET /api/articles/daily`. The `articles.json` bundle file and `Bundle+Resource` extension remain in the project for use by other resource types in future phases.

### Requirement: ArticlesServiceProtocol exposes allArticles and articles(for:)
**Reason**: These methods have no callers anywhere in the app and are being removed to reduce dead surface area.
**Migration**: No migration needed — nothing calls these methods.
