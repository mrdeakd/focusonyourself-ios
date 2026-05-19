## ADDED Requirements

### Requirement: Services contain only network calls

A Service SHALL only call `networkClient` (or the underlying HTTP layer). A Service MUST NOT touch `UserDefaults`, `Keychain`, `HealthKit`, `StoreKit`, `AVAudio`, `UNUserNotificationCenter`, `FoundationModels`, or any other device framework. A Service MUST NOT contain caching logic, branching between alternate paths, validation, business-rule transformations, or held state beyond what's needed for the network call itself.

A Service MAY encode typed inputs into URL/query/body and decode the response (including `.toBackendModel()` / `.toDomainModel()` Codable mappings). A Service receives prepared parameters from its caller (Use Case or ViewModel) and returns mapped models.

#### Scenario: New network endpoint

- **WHEN** the app needs a new backend endpoint
- **THEN** a Service is added at `Services/<Domain>/<Name>Service.swift` + protocol
- **AND** the Service injects only `networkClient`
- **AND** the Service has no other `@Injected` dependencies

#### Scenario: Audit invariant

- **WHEN** the layering invariant is audited
- **THEN** `grep -rln "UserDefaults\|Keychain\|HealthKit\|StoreKit\|AVAudio\|UNUserNotificationCenter\|FoundationModels" FocusOnYourself/Services/ --include="*.swift"` SHALL return empty output

#### Scenario: Forbidden patterns in a Service

- **WHEN** a Service file is reviewed
- **THEN** it MUST NOT contain a guard validating inputs (e.g. empty-check), a cache lookup, a branch on a feature flag, a fallback to alternate paths, or held state beyond constants

### Requirement: Stores wrap multi-consumer device frameworks

When two or more consumers (Use Cases or ViewModels) need the same device-framework primitive, the framework SHALL be wrapped in a Store at `Stores/<Domain>/<Name>Store.swift` + protocol. Single-consumer device frameworks remain inlined in their sole consumer.

A Store SHALL be a thin wrapper: no business logic, no validation, no branching, no held state beyond constants. Same rules as Services.

Stores SHALL be registered in `App/Container+App.swift` under `// MARK: - Stores` using their protocol type as `.singleton`. The currently registered stores are `keychainStore` and `userDefaultsStore`.

#### Scenario: Keychain extraction

- **WHEN** Keychain is used by both `AuthUseCase` and `URLSessionNetworkClient`
- **THEN** the access is encapsulated in `KeychainStore` (`save(_:for:)`, `load(_:)`, `delete(_:)` by string key)
- **AND** no other file references `Keychain.default` directly

#### Scenario: UserDefaults extraction

- **WHEN** UserDefaults is used by multiple consumers (`ProfileUseCase`, `CheckInUseCase`, `SettingsUseCase`, `PurchaseUseCase`, `HomeViewModel`)
- **THEN** the access is encapsulated in `UserDefaultsStore` (typed by `UserDefaultsKey`)
- **AND** no other file instantiates `UserDefaults(suiteName:)` directly

#### Scenario: Single-consumer device framework

- **WHEN** a device framework (HealthKit, AVAudio, StoreKit, UNUserNotificationCenter, FoundationModels) has exactly one consumer
- **THEN** it is inlined in that consumer, NOT extracted to a Store
- **AND** extraction to a Store happens only when a second consumer appears

#### Scenario: Future Store (database, etc.)

- **WHEN** a future feature needs a new device-framework primitive shared across consumers (e.g. SwiftData/SQLite for an offline database)
- **THEN** a new Store is created at `Stores/<Domain>/<Name>Store.swift` following the same shape as `KeychainStore` and `UserDefaultsStore`

### Requirement: Models split by purpose, one type per file

Domain models SHALL live in `FocusOnYourself/Domain/Models/`. Wire-format models (request bodies, response payloads, backend variants, response envelopes) SHALL live in `FocusOnYourself/Networking/Models/`.

Every top-level struct or enum SHALL live in its own file, named `<TypeName>.swift`. Multiple types in one file are forbidden — including conceptually-related types (e.g. `MeditationStep` lives in its own file even though it's only used inside `MeditationSession`).

**Exception**: when mapper extensions exist (`toBackendModel()` / `toDomainModel()`), both extensions co-locate with the backend type in the backend type's file. This is the only case where a model file contains more than one top-level declaration.

#### Scenario: Domain enum

- **WHEN** an enum represents a domain concept (`Mood`, `AffirmationCategory`, `MeditationCategory`, `ArticleTopic`)
- **THEN** it lives at `Domain/Models/<EnumName>.swift` as the sole top-level declaration

#### Scenario: Wire-format request or response

- **WHEN** a type is sent as a request body or received as a response payload
- **THEN** it lives at `Networking/Models/<TypeName>.swift` as the sole top-level declaration

#### Scenario: Nested wire types extracted

- **WHEN** a wire-format type references another wire-format type (e.g. `MeditationSession` has `[MeditationStep]`)
- **THEN** the inner type lives in its own file (`Networking/Models/MeditationStep.swift`) — never embedded in the outer type's file

### Requirement: Backend models live in `Networking/Models/` with both mappers when shapes differ

Every model used in a network call (request body, response payload, response wrapper) SHALL live in `FocusOnYourself/Networking/Models/`. Domain models live in `FocusOnYourself/Domain/Models/`.

When a backend model's wire shape differs from the corresponding domain shape, **both** mappers SHALL exist in the backend model file:

```swift
extension <DomainType> {
    func toBackendModel() -> <BackendType> { … }
}

extension <BackendType> {
    func toDomainModel() -> <DomainType>? { … }
}
```

Mapper naming SHALL be exactly `toBackendModel()` and `toDomainModel()`. `toDomainModel()` returns an optional when any field requires validation. Call sites use `compactMap { $0.toDomainModel() }` on collections.

#### Scenario: New backend model

- **WHEN** a Service introduces a request body or response payload type
- **THEN** the type SHALL be defined in `Networking/Models/<Name>.swift`
- **AND** it SHALL NOT live in `Models/`

#### Scenario: Wire shape matches domain shape

- **WHEN** a backend response can be consumed directly without translation (e.g. `LoginBody`, `AuthResponse`)
- **THEN** no mappers are required
- **AND** the backend type may be used as-is by the Use Case / ViewModel that consumes the Service

#### Scenario: Wire shape diverges from domain shape

- **WHEN** any field needs renaming, enum conversion, validation, or restructuring between wire and domain
- **THEN** both `toBackendModel()` (in a `<DomainType>` extension) AND `toDomainModel() -> <DomainType>?` (in a `<BackendType>` extension) SHALL exist in the backend model file
- **AND** the Service uses these mappers in the 4-line template (`let body = checkIn.toBackendModel()` or `return response.compactMap { $0.toDomainModel() }`)

#### Scenario: Bidirectional symmetry

- **WHEN** one mapper exists for a type pair
- **THEN** the inverse mapper SHALL also exist in the same file, even if only one direction is currently called
- **AND** the file SHALL NOT split the two mappers across separate files

### Requirement: Service methods follow the 4-line template

Every Service method SHALL follow this exact structure, in this order:

1. `let path = "..."` — endpoint base path as a string literal, no query string
2. `let <name> = <encoded value>` — zero or more `let` lines that encode typed inputs into wire-format values (joined arrays, `.toBackendModel()`, date formatting, etc.)
3. `let response: <T> = try await networkClient.<verb>(...)` — the single network call, interpolating the path and params at the call site
4. `return response` or `return response.map { ... }` / `return response.compactMap { ... }` — the return statement, optionally with a final mapping (typically `.toDomainModel()`)

For void-returning calls, step 3 becomes `let _: EmptyResponse = try await networkClient.post(path, body: body)` and step 4 is omitted.

#### Scenario: GET with encoded query params

- **WHEN** a Service method fetches by typed parameters
- **THEN** the body is structured as:
  ```swift
  let path = "/api/affirmations/batch"
  let categoryParams = categories.map(\.rawValue).joined(separator: ",")
  let response: [CachedAffirmation] = try await networkClient.get(
      "\(path)?categories=\(categoryParams)&count=\(count)"
  )
  return response
  ```

#### Scenario: GET with model translation

- **WHEN** the response shape differs from the domain shape
- **THEN** the final line maps via `compactMap { $0.toDomainModel() }` (or `map`), e.g.:
  ```swift
  let path = "/api/checkins"
  let response: [BackendCheckIn] = try await networkClient.get(path)
  return response.compactMap { $0.toDomainModel() }
  ```

#### Scenario: POST with body and typed response

- **WHEN** a Service method posts a body and reads a typed response
- **THEN** the body is structured as:
  ```swift
  let path = "/api/auth/login"
  let body = LoginBody(email: email, password: password)
  let response: AuthResponse = try await networkClient.post(path, body: body)
  return response
  ```

#### Scenario: POST with no response body

- **WHEN** the endpoint returns no useful payload
- **THEN** the call is discarded with a typed `EmptyResponse`:
  ```swift
  let path = "/api/checkins"
  let body = checkIn.toBackendModel()
  let _: EmptyResponse = try await networkClient.post(path, body: body)
  ```

#### Scenario: Two alternative endpoints

- **WHEN** a feature has two distinct endpoints (e.g. all-vs-filtered)
- **THEN** the Service SHALL expose two methods, NOT one method with `if/else` branching
- **AND** the caller chooses which to call

#### Scenario: Caller-provided values

- **WHEN** a Service method needs a value that represents a business decision (e.g. "today's date" vs. "any date")
- **THEN** the value SHALL be passed as a parameter from the caller, NOT computed inside the Service
- **EXCEPT** when the value is a pure encoding concern (e.g. ISO8601 formatting of a Date the caller provided)

### Requirement: Use Cases exist only for SHARED logic

A Use Case SHALL exist when, and only when, two or more ViewModels need the same operation. Single-VM logic SHALL remain in the ViewModel until a second ViewModel needs it — at which point the logic SHALL be extracted to a Use Case.

A Use Case is `final class @MainActor` (or `@Observable @MainActor` if it holds reactive state). It lives at `Domain/UseCases/<Feature>/<Name>UseCase.swift` with a corresponding protocol.

A Use Case may inject Services (network) and may hold Calculators as `private let`. A Use Case may inline non-network device frameworks (Keychain, UserDefaults via App Group, UNUserNotificationCenter, StoreKit) — services are network-only, so any device framework lives in the Use Case (or ViewModel) that uses it.

A Use Case MUST NOT inject another Use Case EXCEPT the `@Observable` state-store ones (`ProfileUseCase`, `PurchaseUseCase`) which are explicitly shared reactive state.

#### Scenario: Single-VM operation

- **WHEN** a ViewModel needs an operation that no other ViewModel uses
- **THEN** the logic lives in the ViewModel itself (may inline device frameworks)
- **AND** no Use Case is created for this operation

#### Scenario: Shared logic extraction (second consumer)

- **WHEN** a second ViewModel needs an operation that previously lived in a single ViewModel
- **THEN** the logic SHALL be extracted to a Use Case under `Domain/UseCases/<Feature>/`
- **AND** the Use Case SHALL be registered in `App/Container+App.swift` under `// MARK: - Use Cases`
- **AND** both ViewModels SHALL inject the new Use Case

#### Scenario: State-store Use Case (cross-use-case dependency)

- **WHEN** a Use Case needs to read or mutate shared reactive state held by another Use Case
- **THEN** it MAY inject `ProfileUseCase` or `PurchaseUseCase` (the only `@Observable` state-store Use Cases)
- **AND** it MUST NOT inject any other Use Case

#### Scenario: Forbidden patterns in a Use Case

- **WHEN** a Use Case file is reviewed
- **THEN** it MUST NOT `import SwiftUI` or reference View / Color types
- **AND** it MUST NOT inject a non-state-store Use Case

### Requirement: ViewModels can inject Services and Use Cases

A ViewModel SHALL be `@Observable @MainActor final class`. It MAY inject Use Cases for shared logic and Services directly for single-VM operations. It MAY inline device-framework code (HealthKit, AVAudio, FoundationModels) when only this VM uses that framework — that framework SHALL be extracted to a Use Case as soon as a second VM needs it.

A ViewModel MUST NOT use `Container.shared.resolve(...)`.

#### Scenario: VM uses a Service directly

- **WHEN** a single ViewModel needs to call a network endpoint that no other VM uses
- **THEN** the ViewModel MAY inject the Service via `@ObservationIgnored @Injected(\.<service>)`
- **AND** the ViewModel MAY hold Calculators as `private let` and inline device frameworks

#### Scenario: VM uses a Use Case

- **WHEN** a ViewModel needs an operation that's already in a Use Case
- **THEN** the ViewModel SHALL inject the Use Case rather than the underlying Service

### Requirement: Calculators are pure value types

A Calculator SHALL be a `struct` defined under `Domain/Calculators/<Name>Calculator.swift`, with no `@Injected` properties, no `@Observable` annotation, no `@MainActor`, no `import SwiftUI`. Other framework imports (e.g. `HealthKit` for type mapping) are allowed. A Calculator SHALL take all inputs as method arguments and return values — never read mutable state from a service.

#### Scenario: Pure computation extracted to a Calculator

- **WHEN** a feature has pure logic of ~10+ lines (math, transformations, validation, scoring, mapping rules)
- **THEN** the logic SHALL live in a Calculator struct
- **AND** the consumer (ViewModel or Use Case) SHALL hold the Calculator as `private let calculator = <Name>Calculator()` and pass data in as arguments

### Requirement: Dependency Injection follows the protocol-typed Factory pattern

All Services and Use Cases SHALL be registered in `App/Container+App.swift` using their **protocol type**, never the concrete class. Registrations SHALL be `.singleton`. Registrations are organised into `// MARK: -` sections: Services, Use Cases.

#### Scenario: New Service registration

- **WHEN** a new Service `<Name>Service` is added
- **THEN** `App/Container+App.swift` gains an entry under the `// MARK: - Services` section:
  ```swift
  var <name>Service: Factory<<Name>ServiceProtocol> {
      self { @MainActor in <Name>Service() }.singleton
  }
  ```

#### Scenario: New Use Case registration

- **WHEN** a new Use Case `<Name>UseCase` is added
- **THEN** `App/Container+App.swift` gains an entry under the `// MARK: - Use Cases` section:
  ```swift
  var <name>UseCase: Factory<<Name>UseCaseProtocol> {
      self { @MainActor in <Name>UseCase() }.singleton
  }
  ```

#### Scenario: Repository layer is absent

- **WHEN** the project structure is reviewed
- **THEN** there is no `Domain/Repositories/` folder and no `Data/Repositories/` folder
- **AND** there are no `Factory<…RepositoryProtocol>` registrations in `Container+App.swift`
