## Why

ViewModels currently reach into three layers simultaneously — Services, Repositories, and Use Cases. `HomeViewModel` injects `checkInUseCase` plus four services; `AccountViewModel` injects `authUseCase` plus a repository plus four services. The Repository layer that was added during the previous Clean Architecture pass added indirection without earning its coordination weight in most cases. The result is a muddled stack where no single rule explains what a ViewModel may depend on, and the architecture cannot be enforced for future code.

The change commits to a single-layer rule: **ViewModels access only Use Cases.** Use Cases own all Services and Calculators. Repositories disappear. The rule is codified in `CLAUDE.md` so future development follows the same shape automatically.

## What Changes

- **BREAKING**: Delete the entire Repository layer (`Domain/Repositories/`, `Data/Repositories/`). `CheckInRepositoryImpl`, `ProfileRepositoryImpl`, `AuthRepositoryImpl` and their protocols are removed.
- Absorb `CheckInRepositoryImpl` logic into `CheckInUseCase` — it now injects `profileService`, `checkinsService`, `userDefaultsService` directly.
- Absorb `AuthRepositoryImpl` logic into `AuthUseCase` — it now injects `networkClient`, `keychainService`, `checkinsService`, `profileService` directly and keeps post-login sync orchestration in place.
- Create 9 new Use Cases covering every ViewModel need that previously required direct service access:
  - `ProfileUseCase` — profile metadata read/write, full reset
  - `AffirmationUseCase` — generate batch
  - `ArticlesUseCase` — daily articles
  - `NotificationsUseCase` — request/schedule/cancel
  - `PurchaseUseCase` — isPro, products, purchase, restore, refresh
  - `SettingsUseCase` — factor toggles, clear pending widget check-in
  - `MeditationUseCase` — sessions list
  - `MeditationPlayerUseCase` — speak/stop/playBell audio
  - `HealthKitUseCase` — save mood + factors
- Migrate all 10 ViewModels (`HomeViewModel`, `AccountViewModel`, `InsightsViewModel`, `HistoryViewModel`, `AuthViewModel`, `OnboardingViewModel`, `MeditateViewModel`, `MeditationPlayerViewModel`, `PaywallViewModel`, `AppRootViewModel`) to inject ONLY use cases via `@ObservationIgnored @Injected(\.<name>UseCase)`.
- Update `App/Container+App.swift` — register 9 new use cases, remove 3 repository registrations.
- Update `CLAUDE.md` to encode the single-layer architecture rules so all future features follow the same shape.

## Capabilities

### New Capabilities
- `mvvm-architecture`: The canonical layered architecture rule set — Screens → ViewModels → Use Cases → Services + Calculators, with the strict invariant that ViewModels inject only Use Cases and Use Cases never depend on other Use Cases. This spec is the contract that all future feature work must satisfy.

### Modified Capabilities
<!-- none — no existing specs in openspec/specs/ -->

## Impact

- **Code structure**: ~18 new Swift files (9 use case protocols + 9 implementations) under `Domain/UseCases/`. 6 files deleted (`Domain/Repositories/*.swift`, `Data/Repositories/*.swift`). The `Data/` and `Domain/Repositories/` folders are removed entirely. Every existing ViewModel file is modified.
- **DI**: `App/Container+App.swift` gains 9 use case registrations and loses 3 repository registrations.
- **Behavior**: No user-visible change. Functional smoke tests after migration: check-in records → streak updates and widget reloads; sign-in syncs check-ins; reset returns to onboarding; paywall purchase flow runs; meditation playback works.
- **Tests**: None (project has no test target). Verification is build success + SwiftLint clean + manual smoke.
- **Future development**: All new features must follow the `mvvm-architecture` spec. A grep invariant locks this in: `grep -rn "@Injected" FocusOnYourself/Features --include="*ViewModel.swift" | grep -v "UseCase"` must return empty.
