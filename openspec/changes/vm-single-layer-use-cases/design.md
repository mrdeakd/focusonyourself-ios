## Context

The previous Clean Architecture pass introduced a Domain layer (Use Cases + Repository protocols + Calculators) and a Data layer (Repository implementations). In practice the Repository layer turned out to be near-duplicate of either a thin Service (`ProfileRepositoryImpl` is pure delegation) or a Use Case (`CheckInRepositoryImpl` essentially mirrors `CheckInUseCase` methods). Meanwhile ViewModels still reach into Services directly for things that never got a Use Case (affirmations, articles, notifications, purchase, settings, meditation, healthkit), so the architecture is inconsistent.

The current state of ViewModel injections:

```
HomeViewModel        → checkInUseCase + profileService + affirmationService
                       + purchaseService + articlesService + userDefaultsService
                       + Container.shared.healthKitService
AccountViewModel     → profileService + notificationService + purchaseService
                       + userDefaultsService + authUseCase + profileRepository
InsightsViewModel    → insightsUseCase + purchaseService
HistoryViewModel     → checkInUseCase                       (clean)
AuthViewModel        → authUseCase                          (clean)
OnboardingViewModel  → notificationService + profileService + purchaseService
MeditateViewModel    → meditationService + purchaseService
MeditationPlayerVM   → meditationAudioService
PaywallViewModel     → purchaseService
AppRootViewModel     → authService + profileService          (already migrated)
```

There is no single rule that says "a ViewModel may depend on X." That makes the layering impossible to enforce for new code.

## Goals / Non-Goals

**Goals:**
- ViewModels depend on **exactly one** layer: Use Cases.
- Every operation a ViewModel performs goes through a Use Case — including thin pass-throughs.
- The Repository layer is removed (its responsibilities collapse into Use Cases).
- The architecture is encoded in `CLAUDE.md` so future development is automatically conformant.
- Reactivity (SwiftUI observation through `ProfileService`/`PurchaseService`) is preserved.
- No user-visible behavior change.

**Non-Goals:**
- Refactoring Services — they stay as thin I/O wrappers; their internal shape is out of scope.
- Refactoring Views or DesignSystem.
- Introducing unit tests or a test target (project has none).
- Refactoring the Widget target (`FocusOnYourselfWidgets/`) — widgets read from App Group UserDefaults directly and that boundary is intentional.
- Changing the persistence model (still UserDefaults + Keychain + remote sync).

## Decisions

### Decision 1: Use Cases as the only VM-facing layer (vs. Repositories)
**Chosen:** Use Cases.
**Alternatives considered:**
- *Repositories only* — would require renaming all current use cases to repositories and would lose the "use case = business operation" semantics. Repositories are typically data-source abstractions, not business operations.
- *Mixed (use cases for complex, services for simple)* — what we have now. Rejected: defeats the goal of a single rule.

**Rationale:** "Use case" maps cleanly to the user-facing operations a ViewModel performs. It is also the standard terminology in Clean Architecture / Onion / Hexagonal. Every screen action corresponds to a use case method; every screen state read corresponds to a use case property. The mental model is consistent.

### Decision 2: Dissolve the Repository layer
**Chosen:** Delete `Domain/Repositories/` and `Data/Repositories/` entirely.
**Alternatives considered:**
- *Keep Repositories, drop Use Cases* — would push cross-repo orchestration (e.g. post-login check-in sync) into ViewModels, which is exactly the "logic in presentation" anti-pattern.
- *Keep both layers* — current state, rejected as muddled.

**Rationale:** The Repository abstraction added a level of indirection that buys real value only when there are multiple swappable data sources for the same domain object. In this app, each domain object has exactly one persistence path. Folding repositories into use cases halves the file count for the same operations and makes the data flow direct.

### Decision 3: Use Cases never depend on other Use Cases
**Chosen:** Cross-feature workflows (like `AuthUseCase.signIn` needing to replace check-ins) are implemented by injecting the underlying *services* into the orchestrating use case, not by injecting other use cases.
**Alternatives considered:**
- *Use cases compose by injecting other use cases* — creates a graph of use cases that can deadlock during initialization (Factory) and creates implicit coupling between feature domains.

**Rationale:** Services are the shared substrate. Use cases sit on top, each independently. This keeps the dependency graph a strict two-level tree (UseCase → Service) instead of a DAG.

### Decision 4: Use Cases are `final class @MainActor`, not `@Observable`
**Chosen:** Plain `final class @MainActor`. Reactive state propagates through underlying `@Observable` services (`ProfileService`, `PurchaseService`) and is exposed via computed properties on the use case.
**Alternatives considered:**
- *Make use cases @Observable* — would double-wrap reactivity. The underlying service is already @Observable; SwiftUI's observation tracks transitive reads at the property-access level. Adding @Observable on the use case adds nothing.

**Rationale:** A computed property `var isPro: Bool { purchaseService.isPro }` is fully reactive because the read of `purchaseService.isPro` happens at the call site, and `PurchaseService` is `@Observable`. SwiftUI tracks property accesses dynamically. No extra observation infrastructure needed.

### Decision 5: Every feature gets a use case, even thin wrappers
**Chosen:** `ArticlesUseCase`, `MeditationUseCase`, `MeditationPlayerUseCase` etc. will be near-1:1 wrappers over their service. Accept this cost.
**Alternatives considered:**
- *Only use cases where logic exists* — would mean ViewModels access services for simple cases and use cases for complex ones. That is the current muddled state.

**Rationale:** Consistency is the value. A single rule ("VMs use only use cases") is more valuable than minimal LOC. Thin wrappers also create an extension point for when a feature does grow logic (e.g. caching, analytics events).

### Decision 6: Encode the rule in CLAUDE.md
**Chosen:** Add a "Layers (strict)" subsection to `CLAUDE.md` Architecture that lists forbidden and allowed dependencies per layer. Add a "When adding a new feature" checklist.
**Rationale:** Without an enforced written rule, the next feature will reintroduce direct service access. The CLAUDE.md instructions are loaded into every Claude Code session for this project, so the rule actively guides future code generation.

## Risks / Trade-offs

- **More files**: ~18 new Swift files (9 use case protocols + 9 implementations). → Mitigation: enforced uniform shape, easy to navigate. Each file is small (<60 lines).
- **Thin wrappers feel pointless**: `ArticlesUseCase.dailyArticles()` is one line. → Mitigation: consistency rule documented in CLAUDE.md. Future logic will land in the use case, not be retrofitted from the service.
- **Reactive bug if read pattern changes**: SwiftUI's observation depends on the underlying `@Observable` service being read at access time, not cached. → Mitigation: design decision 4 codified — use cases expose `var x: T { service.x }` (no caching).
- **Cross-use-case orchestration leaks service knowledge into use cases**: `AuthUseCase` must know about `checkinsService` to do post-login sync. → Mitigation: this is the intended cost of decision 3. The alternative (use cases depending on each other) is worse.

## Migration Plan

Three phases, each independently buildable and shippable:

1. **Phase 1 — Additive**: Create all 9 new use cases + protocols. Modify `CheckInUseCase` and `AuthUseCase` to absorb repository logic. Register everything in `Container+App.swift`. Old repositories remain unused but registered. Build passes; ViewModels still use the old mix. (Risk: low — no existing code path broken.)

2. **Phase 2 — Migration**: For each ViewModel, swap service/repository injections for use case injections in one focused change. Build passes after each ViewModel. Functional smoke test after the last one. (Risk: medium — touches every screen; offset by phase-1 work being already-tested.)

3. **Phase 3 — Cleanup**: Delete `Domain/Repositories/` and `Data/Repositories/` files and folders. Remove repository registrations from `Container+App.swift`. Final build + SwiftLint + grep invariant check. (Risk: low — nothing references the deleted files at this point.)

CLAUDE.md update happens at the end of Phase 1 (so it documents what already exists rather than what's promised) but applies retroactively to the migration in Phase 2.

**Rollback**: Each phase is a single commit on `main`. To roll back: `git revert <commit>` for the phase. Phase 1 is safe to keep even if Phase 2 is reverted (only adds files).

## Open Questions

None — the architecture is concrete and the file-by-file plan is in `tasks.md`.
