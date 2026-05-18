## 1. Phase 1 — Additive: create new Use Cases & absorb Repositories

- [ ] 1.1 Create `Domain/UseCases/Profile/ProfileUseCaseProtocol.swift` (name/categories/notifications/appearance/AI/onboarding getters + setters + resetAll)
- [ ] 1.2 Create `Domain/UseCases/Profile/ProfileUseCase.swift` (injects `profileService` + `userDefaultsService`)
- [ ] 1.3 Create `Domain/UseCases/Affirmation/AffirmationUseCaseProtocol.swift` + `AffirmationUseCase.swift` (injects `affirmationService`)
- [ ] 1.4 Create `Domain/UseCases/Articles/ArticlesUseCaseProtocol.swift` + `ArticlesUseCase.swift` (injects `articlesService`)
- [ ] 1.5 Create `Domain/UseCases/Notifications/NotificationsUseCaseProtocol.swift` + `NotificationsUseCase.swift` (injects `notificationService`)
- [ ] 1.6 Create `Domain/UseCases/Purchase/PurchaseUseCaseProtocol.swift` + `PurchaseUseCase.swift` (injects `purchaseService`; exposes `isPro`, `products`, purchase/restore/refresh)
- [ ] 1.7 Create `Domain/UseCases/Settings/SettingsUseCaseProtocol.swift` + `SettingsUseCase.swift` (injects `userDefaultsService`; factor toggles + clearPendingWidgetCheckIn + resetFactorToggles)
- [ ] 1.8 Create `Domain/UseCases/Meditation/MeditationUseCaseProtocol.swift` + `MeditationUseCase.swift` (injects `meditationService`)
- [ ] 1.9 Create `Domain/UseCases/Meditation/MeditationPlayerUseCaseProtocol.swift` + `MeditationPlayerUseCase.swift` (injects `meditationAudioService`)
- [ ] 1.10 Create `Domain/UseCases/HealthKit/HealthKitUseCaseProtocol.swift` + `HealthKitUseCase.swift` (injects `healthKitService`)
- [ ] 1.11 Modify `Domain/UseCases/CheckIn/CheckInUseCase.swift` — replace `@Injected(\.checkInRepository)` with direct `profileService` + `checkinsService` + `userDefaultsService` injection; inline the repository's `save`/`replaceAll`/`fetchFromServer`/`uploadAll`/`reset`/`mergePendingWidgetCheckIn` logic
- [ ] 1.12 Modify `Domain/UseCases/Auth/AuthUseCase.swift` — replace `@Injected(\.authRepository)` with direct `networkClient` + `keychainService` injection; inline JWT helpers; keep post-login sync orchestration but now performed via `checkinsService` + `profileService` directly (still no use-case-to-use-case dependency)
- [ ] 1.13 Register all 9 new use cases in `App/Container+App.swift` under `// MARK: - Use Cases` section
- [ ] 1.14 Build passes: `xcodebuild -project FocusOnYourself.xcodeproj -scheme FocusOnYourself -destination 'generic/platform=iOS Simulator' build`
- [ ] 1.15 SwiftLint passes: `swiftlint --fix && swiftlint` (no new warnings)

## 2. Update CLAUDE.md to encode the architecture rule

- [ ] 2.1 Replace the existing `### Layers` table under `## Architecture` in `CLAUDE.md` with the strict 6-layer table (Screen / ViewModel / Use Case / Calculator / Service / Model) plus the "What it can depend on" column
- [ ] 2.2 Add subsection **The one-layer rule for ViewModels** with forbidden/allowed bullet lists
- [ ] 2.3 Add subsection **The Use Case layer** with composition rules
- [ ] 2.4 Add subsection **When adding a new feature** with the 6-step checklist
- [ ] 2.5 Add subsections **Forbidden in ViewModels** / **Allowed in Use Cases** / **Forbidden in Use Cases** with explicit lists
- [ ] 2.6 Remove obsolete references to the Repository pattern from `CLAUDE.md` (the Services section currently mentions repositories indirectly)

## 3. Phase 2 — Migrate ViewModels (one ViewModel per commit)

- [ ] 3.1 `HomeViewModel`: replace `profileService` reads with `profileUseCase`, `affirmationService` with `affirmationUseCase`, `articlesService` with `articlesUseCase`, `purchaseService` with `purchaseUseCase`, `userDefaultsService` factor toggles with `settingsUseCase`, `Container.shared.healthKitService()` with `healthKitUseCase`. Build passes.
- [ ] 3.2 `AccountViewModel`: replace `profileService` with `profileUseCase`, `notificationService` with `notificationsUseCase`, `purchaseService` with `purchaseUseCase`, `userDefaultsService` factor toggles with `settingsUseCase`, remove `profileRepository` (use `profileUseCase.resetAll`). Build passes.
- [ ] 3.3 `InsightsViewModel`: replace `purchaseService` with `purchaseUseCase`. Build passes.
- [ ] 3.4 `OnboardingViewModel`: replace `profileService` with `profileUseCase`, `notificationService` with `notificationsUseCase`, `purchaseService` with `purchaseUseCase`. Build passes.
- [ ] 3.5 `MeditateViewModel`: replace `meditationService` with `meditationUseCase`, `purchaseService` with `purchaseUseCase`. Build passes.
- [ ] 3.6 `MeditationPlayerViewModel`: replace `meditationAudioService` with `meditationPlayerUseCase`. Build passes.
- [ ] 3.7 `PaywallViewModel`: replace `purchaseService` with `purchaseUseCase`. Build passes.
- [ ] 3.8 `AppRootViewModel` (inside `FocusOnYourselfApp.swift`): replace `profileService` with `profileUseCase` (for `onboardingCompleted` and `appearanceOverride`). Build passes.
- [ ] 3.9 Functional smoke test in simulator: open Home → complete check-in → streak increments & widget reloads; open Insights → charts render; Account → sign in syncs check-ins, sign out clears tokens, reset returns to onboarding; Paywall → loads products & runs purchase flow; Meditate → list loads & playback works.

## 4. Phase 3 — Delete the Repository layer

- [ ] 4.1 Delete `Domain/Repositories/CheckInRepositoryProtocol.swift`
- [ ] 4.2 Delete `Domain/Repositories/ProfileRepositoryProtocol.swift`
- [ ] 4.3 Delete `Domain/Repositories/AuthRepositoryProtocol.swift`
- [ ] 4.4 Delete `Data/Repositories/CheckInRepositoryImpl.swift`
- [ ] 4.5 Delete `Data/Repositories/ProfileRepositoryImpl.swift`
- [ ] 4.6 Delete `Data/Repositories/AuthRepositoryImpl.swift`
- [ ] 4.7 Remove empty `Data/Repositories/` and `Data/` directories
- [ ] 4.8 Remove empty `Domain/Repositories/` directory
- [ ] 4.9 Remove `checkInRepository`, `profileRepository`, `authRepository` registrations from `App/Container+App.swift`
- [ ] 4.10 Build passes
- [ ] 4.11 SwiftLint passes
- [ ] 4.12 Invariant grep returns empty: `grep -rn "@Injected" FocusOnYourself/Features --include="*ViewModel.swift" | grep -v "UseCase"`
- [ ] 4.13 Invariant grep returns empty: `grep -rn "Repository" FocusOnYourself --include="*.swift"`

## 5. Verify & validate

- [ ] 5.1 Run `openspec validate vm-single-layer-use-cases` — passes
- [ ] 5.2 Save a project memory recording the new architecture rule (replace the existing `project_clean_arch` memory with the updated single-layer rule)
- [ ] 5.3 Commit phases as separate commits on `main` with messages:
  - "feat: add use case layer covering all VM dependencies (phase 1)"
  - "docs: encode single-layer architecture rule in CLAUDE.md"
  - "refactor: migrate ViewModels to use-case-only injection (phase 2)"
  - "refactor: delete Repository layer (phase 3)"
