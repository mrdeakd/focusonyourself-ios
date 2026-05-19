## ADDED Requirements

### Requirement: Services contain only network calls

A Service SHALL only call `networkClient` (or the underlying HTTP layer). A Service MUST NOT touch `UserDefaults`, `Keychain`, `HealthKit`, `StoreKit`, `AVAudio`, `UNUserNotificationCenter`, `FoundationModels`, or any other device framework. A Service MUST NOT contain caching logic, branching between alternate paths, business-rule transformations, or held state beyond what's needed for the network call itself.

A Service receives prepared parameters from its caller (Use Case or ViewModel) and returns the raw decoded response.

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
- **THEN** it MUST NOT contain a date check, a cache lookup, a branch on a feature flag, a mapping rule, a formula, or held state beyond constants

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
