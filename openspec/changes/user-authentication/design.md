# User Authentication — Design

## Context

The app has a thin networking layer (`NetworkClientProtocol` → `URLSessionNetworkClient`) that reaches `https://focusonyourself-backend.onrender.com`. All requests are currently unauthenticated — bare URLRequests with no headers beyond Content-Type.

User data lives in `UserProfile` (Codable struct) persisted to `NSUbiquitousKeyValueStore` (iCloud KVS). `ContentView` branches on `profileService.profile.onboardingCompleted` to show onboarding or the main tab view. There is no auth state anywhere in the app.

## Goals

- Users can create an account with email + password
- Users can sign in and receive a JWT access token (15 min TTL) + refresh token (30 day TTL)
- iOS stores tokens in Keychain; never in UserDefaults or iCloud
- All API requests automatically include `Authorization: Bearer <token>` when a token exists
- Backend validates Bearer tokens on protected routes via middleware
- Auth is opt-in — the app remains fully usable without an account
- LEARN.md documents: bcrypt, JWT anatomy, access vs refresh tokens, middleware pattern

## Non-Goals

- Apple Sign In (planned follow-up change)
- Server-side profile sync (planned follow-up — auth is the prerequisite)
- Email verification or password reset
- OAuth / social login
- Two-factor authentication
- Forcing users to create an account

## Decisions

### 1. JWT with short-lived access tokens + long-lived refresh tokens

Access token: 15-minute TTL, stateless, verified on every request. Refresh token: 30-day TTL, stored server-side in a `refreshTokens` table so individual devices can be revoked independently.

On each app `.active` scene transition, `AuthService.refreshTokenIfNeeded()` runs silently — if the access token is expired but the refresh token is valid, it swaps without user interaction.

**Alternative considered:** Single long-lived token — simpler, but unrevocable and a security anti-pattern.

### 2. Keychain for token storage, not UserDefaults

JWTs are credentials. iOS Keychain items are encrypted at rest, per-device, and not included in iCloud backups by default. `UserDefaults` is plaintext and potentially iCloud-synced — a token there would roam to other devices and could be extracted from a backup.

**No third-party library.** `Security` framework CRUD for a handful of keychain items is ~50 lines. Adding a dependency for this would be unnecessary.

### 3. Optional auth — no wall on the app

Forcing account creation causes measurable Day-1 abandonment in wellness apps. Auth unlocks value (future sync, web access) but must not be a barrier. The full app works without login; a "Create account" CTA lives in Settings.

### 4. bcrypt for password hashing (cost factor 12)

Industry standard for password storage. Adaptive cost factor resists brute force as hardware improves. Factor 12 takes ~250ms on current server hardware — acceptable for UX, meaningful friction for attackers. Passwords are never stored in plaintext or with reversible hashing.

### 5. `post<T, B>` added to NetworkClientProtocol

Auth endpoints require POST with a JSON body. The existing protocol has only `get<T>`. The addition:

```typescript
func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
```

`URLSessionNetworkClient` implements it: encode `body` with `JSONEncoder`, set `Content-Type: application/json`, apply the same 200–299/304/error response handling as `get`.

### 6. Bearer injection is automatic and transparent to callers

`URLSessionNetworkClient` is constructed with a `KeychainService` reference. On every request it reads the access token from Keychain and adds `Authorization: Bearer <token>` if one exists. Callers (services, ViewModels) never handle tokens directly — they just call `get` or `post` as before. Unauthenticated backend endpoints ignore the header silently.

### 7. UI screens designed in Pencil.dev before implementation

`SignInScreen`, `SignUpScreen`, `AuthFlow`, and `SettingsAccountSection` are designed in the Pencil.dev design file using existing design-system variables before any Swift code is written. Implementation reads the node IDs from the design and matches them 1:1, same workflow used for `CheckedInCardView`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Existing iCloud users have no account | Auth is opt-in; iCloud sync continues unchanged for non-authenticated users |
| Refresh token reuse attack | Store refresh tokens server-side; delete on use and issue a new one (rotation) |
| Token expiry mid-request | `AuthService` retries once after a silent refresh; surfaces error on second failure |
| Dev environment differs from production | `.env` + `.env.example` document all secrets; `LEARN.md` explains how to run locally |

## Migration Plan

1. Add `User` + `RefreshToken` tables to Prisma; run migration; verify with `npx prisma studio`
2. Implement `src/auth/service.ts` (bcrypt + JWT) and `src/auth/router.ts`; verify with `curl`
3. Implement `authenticate` middleware; apply to `GET /api/auth/me`; verify 401 vs 200
4. Design auth screens in Pencil.dev (all 4 views)
5. Implement `KeychainService` in iOS
6. Implement `AuthService`; smoke-test register + login + refresh + logout cycle
7. Update `NetworkClientProtocol` + `URLSessionNetworkClient` (post + Bearer injection)
8. Register in Container; wire into app boot
9. Implement `SignInScreen`, `SignUpScreen`, `AuthFlow`, `SettingsAccountSection` from Pencil designs
10. Full build + SwiftLint 0 violations + curl verification suite

## Open Questions

_None — all decisions resolved above._
