## ADDED Requirements

### Requirement: ViewModels depend only on Use Cases

A ViewModel SHALL inject only Use Cases via `@ObservationIgnored @Injected(\.<name>UseCase)`. A ViewModel MUST NOT inject services, network clients, repositories, `UserDefaults`, `Keychain`, `URLSession`, `WidgetCenter`, `UNUserNotificationCenter`, `Container.shared.resolve(...)`, or any other infrastructure type.

#### Scenario: New ViewModel injects only use cases

- **WHEN** a developer adds a new `@Observable @MainActor final class <Name>ViewModel`
- **THEN** every `@Injected(...)` property in that class SHALL resolve to a `<Something>UseCaseProtocol`

#### Scenario: Existing ViewModel needs new functionality without a use case

- **WHEN** a ViewModel needs functionality that has no corresponding Use Case
- **THEN** the developer SHALL create the Use Case (+ protocol) first under `Domain/UseCases/<Feature>/` and register it in `App/Container+App.swift`
- **AND** the ViewModel SHALL then inject only that Use Case — not the underlying service

#### Scenario: Reactive state from an Observable service

- **WHEN** a ViewModel needs reactive state currently held by an `@Observable` service such as `ProfileService` or `PurchaseService`
- **THEN** the ViewModel SHALL read it through a Use Case computed property (e.g. `profileUseCase.name`, `purchaseUseCase.isPro`)
- **AND** the ViewModel SHALL NOT inject the `@Observable` service directly

#### Scenario: Invariant check

- **WHEN** the layering invariant is audited
- **THEN** `grep -rn "@Injected" FocusOnYourself/Features --include="*ViewModel.swift" | grep -v "UseCase"` SHALL return empty output

### Requirement: Use Cases own all business logic and I/O coordination

A Use Case SHALL be a `final class @MainActor` (not `@Observable`) defined in `Domain/UseCases/<Feature>/<Name>UseCase.swift` with a corresponding protocol in `<Name>UseCaseProtocol.swift`. A Use Case MAY inject any number of Services via `@Injected` and MAY hold pure Calculator structs as `private let`. A Use Case MUST NOT inject other Use Cases.

#### Scenario: Use case wraps a service

- **WHEN** a feature exposes a service operation (e.g. fetch daily articles)
- **THEN** a Use Case SHALL be created that injects the service and exposes the operation through its protocol
- **AND** the operation MAY be a one-line passthrough — thin wrappers are explicitly allowed

#### Scenario: Cross-feature orchestration

- **WHEN** a Use Case method must perform work that touches multiple feature domains (e.g. `AuthUseCase.signIn` performs auth then replaces local check-ins with server check-ins)
- **THEN** the Use Case SHALL inject the underlying *services* it needs (e.g. `networkClient`, `keychainService`, `checkinsService`, `profileService`)
- **AND** the Use Case MUST NOT inject another Use Case to accomplish the orchestration

#### Scenario: Use case exposes reactive state

- **WHEN** a Use Case exposes state held in an `@Observable` service
- **THEN** the Use Case SHALL expose it as a computed property that reads the service at access time (e.g. `var isPro: Bool { purchaseService.isPro }`)
- **AND** the Use Case MUST NOT cache the value in a stored property

#### Scenario: Forbidden imports

- **WHEN** a Use Case file is reviewed
- **THEN** it MUST NOT contain `import SwiftUI`, `import Charts`, or any reference to View, Color, or other UI types

### Requirement: Services are thin I/O wrappers

A Service SHALL wrap exactly one external system (network endpoint family, `UserDefaults`, `Keychain`, `HealthKit`, `StoreKit`, `UNUserNotificationCenter`, `AVAudioPlayer`, `FoundationModels`, etc.). A Service SHALL live under `Services/<Domain>/<Name>Service.swift` with a corresponding `<Name>ServiceProtocol.swift`. A Service MUST NOT contain business logic, orchestrate other services for a domain purpose, or expose ViewModel-facing convenience methods.

#### Scenario: Service wraps one external system

- **WHEN** a new external system is introduced (e.g. a new SDK or API)
- **THEN** a Service is created that wraps only that system
- **AND** any business rules or cross-system coordination SHALL live in a Use Case, not the Service

#### Scenario: ViewModel never injects a service

- **WHEN** a ViewModel needs functionality provided by a service
- **THEN** the ViewModel SHALL inject the appropriate Use Case which itself injects the service

### Requirement: Calculators are pure value types

A Calculator SHALL be a `struct` defined under `Domain/Calculators/<Name>Calculator.swift`, with no `@Injected` properties, no `@Observable` annotation, no `@MainActor`, no `import SwiftUI`. A Calculator SHALL take all inputs as method arguments and return values — never read mutable state from a service.

#### Scenario: Pure computation extracted to calculator

- **WHEN** a feature needs non-trivial computation (date math, statistics, scoring, validation)
- **THEN** the logic SHALL live in a Calculator struct
- **AND** the Use Case that orchestrates the operation SHALL hold the Calculator as `private let calculator = <Name>Calculator()` and pass the relevant data in as arguments

### Requirement: Dependency Injection follows the protocol-typed Factory pattern

All Services, Use Cases, and any other injected dependency SHALL be registered in `App/Container+App.swift` using their **protocol type**, never the concrete class. Registrations SHALL be `.singleton`. Registrations are organised into `// MARK: -` sections: Services, Use Cases.

#### Scenario: New use case registration

- **WHEN** a new Use Case `FooUseCase` is added
- **THEN** `App/Container+App.swift` gains an entry under the `// MARK: - Use Cases` section in the form:
  ```swift
  var fooUseCase: Factory<FooUseCaseProtocol> {
      self { @MainActor in FooUseCase() }.singleton
  }
  ```
- **AND** ViewModels inject it via `@ObservationIgnored @Injected(\.fooUseCase) private var fooUseCase`

#### Scenario: Repository layer is absent

- **WHEN** the project structure is reviewed
- **THEN** there is no `Domain/Repositories/` folder and no `Data/Repositories/` folder
- **AND** there are no `Factory<…RepositoryProtocol>` registrations in `Container+App.swift`
