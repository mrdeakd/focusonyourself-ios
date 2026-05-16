## ADDED Requirements

### Requirement: NetworkClientProtocol defines the network boundary
`NetworkClientProtocol` SHALL be a Swift protocol with a single method `func get<T: Decodable>(_ path: String) async throws -> T`. It SHALL live in `FocusOnYourself/Networking/NetworkClientProtocol.swift` and be the only type that services depend on — never the concrete implementation.

#### Scenario: Service depends on protocol, not implementation
- **WHEN** `ArticlesService` is initialised
- **THEN** it receives a `NetworkClientProtocol` value, not a `URLSessionNetworkClient` directly

### Requirement: URLSessionNetworkClient is the concrete implementation
`URLSessionNetworkClient` SHALL be a Swift struct that conforms to `NetworkClientProtocol`. It SHALL hold a `baseURL: URL` set to `http://localhost:3000`, build the full request URL from `baseURL + path`, perform the request via `URLSession.shared`, and decode the response body as `T` using `JSONDecoder`.

#### Scenario: Successful GET request
- **WHEN** `URLSessionNetworkClient().get("/api/articles/daily?date=2026-05-16")` is called and the server returns HTTP 200 with valid JSON
- **THEN** the method returns a decoded value of type `T` without throwing

#### Scenario: Server returns non-200 status
- **WHEN** the server returns any HTTP status code other than 200
- **THEN** the method throws `NetworkError.badResponse(statusCode)`

#### Scenario: Network is unavailable
- **WHEN** no server is reachable at the base URL
- **THEN** the method throws a `URLError` propagated from `URLSession`

### Requirement: NetworkError covers all failure cases
A `NetworkError` enum SHALL be defined in `FocusOnYourself/Networking/NetworkError.swift` with at least two cases: `invalidURL` (malformed path cannot form a URL) and `badResponse(Int)` (server returned a non-200 status, carrying the status code).

#### Scenario: Invalid path produces invalidURL error
- **WHEN** the path string cannot be combined with the base URL to form a valid URL
- **THEN** `get(_:)` throws `NetworkError.invalidURL`

### Requirement: URLSessionNetworkClient is registered in the DI container and injected via constructor
`URLSessionNetworkClient` SHALL be registered in `Container+App.swift` as a singleton under `networkClient: Factory<NetworkClientProtocol>`. Services that need network access SHALL receive it as a constructor parameter (matching the existing service injection pattern).

#### Scenario: ArticlesService receives network client via constructor
- **WHEN** the DI container creates `ArticlesService`
- **THEN** it passes `self.networkClient()` as the constructor argument

### Requirement: Base URL targets localhost and requires no ATS changes
The base URL SHALL be `http://localhost:3000`. No `NSAppTransportSecurity` entry is needed in `Info.plist` because `localhost` is exempt from App Transport Security by default.

#### Scenario: App runs in iOS Simulator
- **WHEN** the app runs in the iOS Simulator and the backend container is running on the same machine
- **THEN** requests to `http://localhost:3000` succeed without ATS errors

### Requirement: NetworkClient is used only by services, never by ViewModels or Views
`NetworkClientProtocol` and `URLSessionNetworkClient` SHALL only appear inside the `Networking/` layer and service implementations. ViewModels and Views SHALL remain unaware of the network layer.

#### Scenario: HomeViewModel is unchanged
- **WHEN** `HomeViewModel` accesses articles
- **THEN** it calls `articlesService.dailyArticles()` as before, with no reference to any networking type
