# User Authentication — Proposal

**Status:** Draft
**Created:** 2026-05-17

## Why

The app currently stores all data on-device (iCloud KVS). There is no concept of a user account, which means:

- Data is device-bound — reinstalling wipes everything not synced by iCloud
- No foundation for server-side profile sync, push notifications, or a web dashboard
- All backend routes are open — no way to scope content or data to a user

User authentication is the prerequisite for every meaningful backend feature that follows. It also teaches the most fundamental backend skill: JWT-based auth, password hashing, and token lifecycle management.

## What Changes

### Backend

- New `User` model in Prisma schema (`id`, `email`, `passwordHash`, `createdAt`, `updatedAt`)
- New `RefreshToken` model for server-side token storage and rotation
- 5 new endpoints:
  - `POST /api/auth/register` — creates account, returns access + refresh tokens
  - `POST /api/auth/login` — validates credentials, returns access + refresh tokens
  - `POST /api/auth/refresh` — exchanges a valid refresh token for a new access token
  - `POST /api/auth/logout` — invalidates the refresh token
  - `GET /api/auth/me` — returns the authenticated user's id + email (protected)
- `authenticate` middleware — validates `Authorization: Bearer <jwt>` header, attaches `req.user` to the request; applied to all future protected routes
- `LEARN.md` section covering: bcrypt, JWT anatomy, access vs refresh token pattern, middleware

### iOS

- `KeychainService` — wraps Security framework to store/retrieve/delete access + refresh tokens securely (never UserDefaults)
- `AuthService` — async throws methods: `register(email:password:)`, `signIn(email:password:)`, `signOut()`, `refreshTokenIfNeeded()`, `isAuthenticated: Bool`
- `NetworkClientProtocol` — add `post<T>(_ path:, body:) async throws -> T`; inject `Authorization: Bearer` header automatically when a token is available
- `ContentView` — auth is optional; the app remains fully functional without an account
- Sign In screen and Sign Up screen — designed in Pencil.dev, implemented from those designs
- Settings account section — shows email when signed in; "Create account" CTA when signed out

## Capabilities

- `backend-user-model` — Prisma User + RefreshToken schema, migration, dev seed
- `backend-auth-api` — 5 endpoints, bcrypt, JWT sign/verify, refresh token rotation
- `backend-auth-middleware` — `authenticate()` Express middleware for protected routes
- `ios-keychain-service` — KeychainService wrapping Security framework
- `ios-auth-service` — AuthService with full token lifecycle management
- `ios-network-auth` — automatic Bearer token injection in URLSessionNetworkClient
- `ios-auth-state` — AuthService in DI container; auth-aware app boot
- `ios-auth-ui` — SignInScreen, SignUpScreen, AuthFlow (designed in Pencil.dev first)
- `ios-settings-account` — account section in SettingsScreen + SettingsViewModel

## Impact

### Backend files created/modified

| File | Change |
|------|--------|
| `prisma/schema.prisma` | Add User + RefreshToken models |
| `src/auth/router.ts` | 5 auth route handlers |
| `src/auth/service.ts` | bcrypt + JWT business logic |
| `src/middleware/authenticate.ts` | Bearer JWT middleware |
| `src/types/express.d.ts` | Extend Request with `user?: { id: string }` |
| `LEARN.md` | Auth section |

### iOS files created/modified

| File | Change |
|------|--------|
| `Services/KeychainService.swift` | New — Security framework wrapper |
| `Services/AuthService.swift` | New — `@Observable @MainActor` auth service |
| `Services/AuthServiceProtocol.swift` | New — protocol |
| `Networking/NetworkClientProtocol.swift` | Add `post` method |
| `Networking/URLSessionNetworkClient.swift` | Implement `post` + Bearer injection |
| `App/Container+App.swift` | Register AuthService, KeychainService; update networkClient |
| `App/ContentView.swift` | Auth-aware routing (non-breaking) |
| `Features/Auth/AuthViewModel.swift` | New |
| `Features/Auth/AuthFlow.swift` | New — Sign In / Sign Up container |
| `Features/Auth/SignInScreen.swift` | New — implemented from Pencil design |
| `Features/Auth/SignUpScreen.swift` | New — implemented from Pencil design |
| `Features/Settings/SettingsViewModel.swift` | Add account properties |
| `Features/Settings/Components/SettingsAccountSection.swift` | New — implemented from Pencil design |
