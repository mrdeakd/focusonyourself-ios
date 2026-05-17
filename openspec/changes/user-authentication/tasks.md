# User Authentication — Tasks

## 1. Backend — Prisma Schema

- [ ] 1.1 Add `User` model: `id` (cuid), `email` (unique, String), `passwordHash` (String), `createdAt`, `updatedAt`
- [ ] 1.2 Add `RefreshToken` model: `id` (cuid), `token` (unique, String), `userId` (FK → User), `expiresAt` (DateTime), `createdAt`
- [ ] 1.3 Run `npx prisma migrate dev --name add-user-auth`
- [ ] 1.4 Add seed entry: dev user `dev@test.com` / `password123` (hashed)
- [ ] 1.5 Verify: `npx prisma generate` and `npx prisma studio` — tables visible

## 2. Backend — Auth Service

- [ ] 2.1 Create `src/auth/service.ts`; install `bcryptjs jsonwebtoken @types/bcryptjs @types/jsonwebtoken`
- [ ] 2.2 `hashPassword(plain: string): Promise<string>` — `bcrypt.hash(plain, 12)`
- [ ] 2.3 `comparePassword(plain: string, hash: string): Promise<boolean>` — `bcrypt.compare`
- [ ] 2.4 `signAccessToken(userId: string): string` — `jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: '15m' })`
- [ ] 2.5 `signRefreshToken(userId: string): string` — `jwt.sign({ sub: userId }, REFRESH_SECRET, { expiresIn: '30d' })`
- [ ] 2.6 `storeRefreshToken(token, userId, expiresAt)` — `prisma.refreshToken.create(...)`
- [ ] 2.7 `rotateRefreshToken(oldToken)` — verify, delete old, sign + store new, return new token

## 3. Backend — Auth Routes

- [ ] 3.1 Create `src/auth/router.ts` with `express.Router()`
- [ ] 3.2 `POST /api/auth/register` — check email uniqueness (409 if taken), hash password, create User, issue + store tokens, return `{ accessToken, refreshToken, user: { id, email } }`
- [ ] 3.3 `POST /api/auth/login` — find User by email (401 if not found), comparePassword (401 if wrong), issue tokens, return same shape as register
- [ ] 3.4 `POST /api/auth/refresh` — accept `{ refreshToken }` body, rotateRefreshToken, return `{ accessToken, refreshToken }`
- [ ] 3.5 `POST /api/auth/logout` — delete refresh token from DB, return 204
- [ ] 3.6 `GET /api/auth/me` — apply `authenticate` middleware, return `{ id, email }` from `req.user`
- [ ] 3.7 Register in `src/app.ts`: `app.use('/api/auth', authRouter)`
- [ ] 3.8 Add `JWT_SECRET` and `REFRESH_SECRET` to `.env` + `.env.example` with placeholder values

## 4. Backend — authenticate Middleware

- [ ] 4.1 Create `src/middleware/authenticate.ts`
- [ ] 4.2 Extract `Authorization` header; split on `' '`; require `Bearer <token>` shape → 401 if malformed
- [ ] 4.3 `jwt.verify(token, JWT_SECRET)` → 401 with `{ error: 'Token expired' }` on `TokenExpiredError`, `{ error: 'Invalid token' }` on any other error
- [ ] 4.4 Attach `req.user = { id: (payload as JwtPayload).sub as string }` on success; call `next()`
- [ ] 4.5 Create `src/types/express.d.ts`: extend `Express.Request` with `user?: { id: string }`
- [ ] 4.6 Verify: `curl GET /api/auth/me` without token → 401; with valid Bearer → 200

## 5. Backend — LEARN.md

- [ ] 5.1 "What is bcrypt?" — one-way adaptive hash, cost factor, why not SHA-256/MD5 for passwords
- [ ] 5.2 "JWT anatomy" — header.payload.signature, base64url encoding, what's inside the payload, signing vs encryption
- [ ] 5.3 "Access vs refresh tokens" — TTL rationale, why keep access tokens short, rotation pattern, server-side revocation
- [ ] 5.4 "authenticate middleware" — Express middleware signature `(req, res, next)`, how Bearer extraction and `jwt.verify` work, how `req.user` is set

## 6. Pencil Design — Auth Screens

- [ ] 6.1 Open `FocusOnYourselfDesign.pen` in Pencil.dev
- [ ] 6.2 Design `SignInScreen` — email field, password field, Sign In button (FoyPrimaryButton), "No account? Create one" link, ScreenHeader "Sign In"
- [ ] 6.3 Design `SignUpScreen` — email, password, confirm password fields, Create Account button, "Already have an account?" link, ScreenHeader "Create Account"
- [ ] 6.4 Design `AuthFlow` — sheet container with `SignInScreen` / `SignUpScreen` toggled by a segmented picker
- [ ] 6.5 Design `SettingsAccountSection` (two states):
  - Signed out: single row "Create account →" (tappable, opens AuthFlow sheet)
  - Signed in: email label row + "Sign Out" row (destructive)
- [ ] 6.6 Record node IDs for each screen root — needed for iOS implementation

## 7. iOS — KeychainService

- [ ] 7.1 Create `FocusOnYourself/Services/KeychainService.swift`
- [ ] 7.2 `func save(key: String, value: String) throws` — `SecItemAdd` with `kSecAttrService`, `kSecAttrAccount`; update via `SecItemUpdate` if already exists
- [ ] 7.3 `func load(key: String) -> String?` — `SecItemCopyMatching` returning `kSecReturnData`; UTF-8 decode
- [ ] 7.4 `func delete(key: String)` — `SecItemDelete`; ignore `errSecItemNotFound`
- [ ] 7.5 Add static constants: `KeychainService.accessTokenKey = "foy.accessToken"`, `.refreshTokenKey = "foy.refreshToken"`, `.userEmailKey = "foy.userEmail"`
- [ ] 7.6 Register in `Container+App.swift`: `var keychainService: Factory<KeychainService> { self { KeychainService() }.singleton }`

## 8. iOS — AuthService

- [ ] 8.1 Create `FocusOnYourself/Services/AuthServiceProtocol.swift`:
  ```swift
  protocol AuthServiceProtocol: AnyObject {
      var isAuthenticated: Bool { get }
      var userEmail: String? { get }
      func register(email: String, password: String) async throws
      func signIn(email: String, password: String) async throws
      func signOut() async
      func refreshTokenIfNeeded() async
  }
  ```
- [ ] 8.2 Create `FocusOnYourself/Services/AuthService.swift` — `@Observable @MainActor final class AuthService: AuthServiceProtocol`
- [ ] 8.3 On init: check Keychain for existing access token → set `isAuthenticated = true` if present; load `userEmail` from Keychain
- [ ] 8.4 `register(email:password:)` — POST `/api/auth/register`; on success store both tokens + email in Keychain; set `isAuthenticated = true`
- [ ] 8.5 `signIn(email:password:)` — POST `/api/auth/login`; store tokens + email; set `isAuthenticated = true`
- [ ] 8.6 `signOut()` — POST `/api/auth/logout` (best effort); delete Keychain tokens + email; set `isAuthenticated = false`
- [ ] 8.7 `refreshTokenIfNeeded()` — decode JWT expiry from access token; if within 60s of expiry, POST `/api/auth/refresh`; update Keychain with new tokens
- [ ] 8.8 Register in `Container+App.swift`: `var authService: Factory<AuthServiceProtocol> { self { @MainActor in AuthService(...) }.singleton }`
- [ ] 8.9 Add `await authService.refreshTokenIfNeeded()` to `FocusOnYourselfApp` `.active` scene phase handler alongside the existing `mergeWidgetCheckIn()` call

## 9. iOS — Network Auth

- [ ] 9.1 Add to `NetworkClientProtocol`:
  ```swift
  func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
  ```
- [ ] 9.2 Implement `post` in `URLSessionNetworkClient` — `JSONEncoder().encode(body)`, `Content-Type: application/json`, same 200–299/304/error handling as `get`
- [ ] 9.3 Add `keychainService: KeychainService` parameter to `URLSessionNetworkClient.init`
- [ ] 9.4 In both `get` and `post`: if `keychainService.load(KeychainService.accessTokenKey) != nil`, add `Authorization: Bearer <token>` header
- [ ] 9.5 Update `Container+App.swift` — inject `keychainService()` when constructing `networkClient`

## 10. iOS — Auth UI (from Pencil designs)

- [ ] 10.1 Create `FocusOnYourself/Features/Auth/AuthViewModel.swift` — `@Observable @MainActor`; `email`, `password`, `confirmPassword: String`; `isLoading: Bool`; `error: ErrorInfo?`; `func signIn() async`, `func register() async`
- [ ] 10.2 Create `FocusOnYourself/Features/Auth/SignInScreen.swift` — implement from Pencil design (task 6.2 node ID)
- [ ] 10.3 Create `FocusOnYourself/Features/Auth/SignUpScreen.swift` — implement from Pencil design (task 6.3 node ID); validate passwords match before calling `register`
- [ ] 10.4 Create `FocusOnYourself/Features/Auth/AuthFlow.swift` — sheet root; segmented picker switches between Sign In and Sign Up; implement from Pencil design (task 6.4 node ID)

## 11. iOS — Settings Account Section

- [ ] 11.1 Add to `SettingsViewModel`: `var isAuthenticated: Bool { authService.isAuthenticated }`, `var accountEmail: String? { authService.userEmail }`, `func signOut() async { await authService.signOut() }`, `var showAuthFlow = false`
- [ ] 11.2 Inject `authService` into `SettingsViewModel` via `@ObservationIgnored @Injected(\.authService)`
- [ ] 11.3 Create `FocusOnYourself/Features/Settings/Components/SettingsAccountSection.swift` — implement both states from Pencil design (task 6.5 node ID)
- [ ] 11.4 Add `SettingsAccountSection(viewModel: viewModel)` to top of `SettingsScreen` scroll content

## 12. iOS — Cleanup

- [ ] 12.1 Remove `// No auth headers` comment in `URLSessionNetworkClient` (now obsolete)
- [ ] 12.2 Audit `UserDefaultsKey` enum — remove any entries fully superseded by Keychain/auth
- [ ] 12.3 Remove any dead code paths in the networking layer exposed by the refactor
- [ ] 12.4 SwiftLint pass: `swiftlint --fix && swiftlint` — 0 violations

## 13. Build & Verification

- [ ] 13.1 `xcodebuild -project FocusOnYourself.xcodeproj -scheme FocusOnYourself -destination 'generic/platform=iOS Simulator' build` — BUILD SUCCEEDED
- [ ] 13.2 `swiftlint --fix && swiftlint` — 0 violations
- [ ] 13.3 `curl -X POST .../api/auth/register -d '{"email":"test@x.com","password":"abc12345"}'` → 201 + tokens
- [ ] 13.4 `curl -X POST .../api/auth/login` with correct creds → 200 + tokens
- [ ] 13.5 `curl -X POST .../api/auth/login` with wrong password → 401
- [ ] 13.6 `curl -X POST .../api/auth/register` with same email again → 409
- [ ] 13.7 `curl GET .../api/auth/me` with Bearer token → 200 + `{ id, email }`
- [ ] 13.8 `curl GET .../api/auth/me` without token → 401
- [ ] 13.9 `curl -X POST .../api/auth/refresh` with valid refresh token → 200 + new access token
- [ ] 13.10 Simulator: register → see account email in Settings → sign out → signed-out state → sign in → signed-in state
