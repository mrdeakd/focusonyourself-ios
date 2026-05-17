# Spec: ios-auth-service

## Overview

Two new iOS services handle secure credential storage (`KeychainService`) and the full authentication lifecycle (`AuthService`). Both are registered as singletons in `Container+App.swift`.

---

## Requirements

### REQ-1: KeychainService

**File:** `FocusOnYourself/Services/KeychainService.swift`

**Description:** Thin wrapper around the iOS Security framework providing save/load/delete for string values keyed by name.

```swift
final class KeychainService {
    static let accessTokenKey  = "foy.accessToken"
    static let refreshTokenKey = "foy.refreshToken"
    static let userEmailKey    = "foy.userEmail"

    func save(key: String, value: String) throws
    func load(key: String) -> String?
    func delete(key: String)
}
```

**Scenarios:**

WHEN `save(key:value:)` is called and no item exists for that key
THEN insert via `SecItemAdd` with `kSecClassGenericPassword`, `kSecAttrService = "FocusOnYourself"`, `kSecAttrAccount = key`

WHEN `save(key:value:)` is called and an item already exists
THEN update via `SecItemUpdate`; do not create a duplicate

WHEN `load(key:)` is called for a key that exists
THEN return the stored string (UTF-8 decoded from `kSecReturnData`)

WHEN `load(key:)` is called for a key that does not exist
THEN return `nil`

WHEN `delete(key:)` is called
THEN call `SecItemDelete`; if result is `errSecItemNotFound` do not throw

---

### REQ-2: AuthServiceProtocol

**File:** `FocusOnYourself/Services/AuthServiceProtocol.swift`

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

---

### REQ-3: AuthService — initialisation

**File:** `FocusOnYourself/Services/AuthService.swift`

**Description:** `@Observable @MainActor final class` that manages the token lifecycle.

**Scenarios:**

WHEN AuthService is initialised
THEN read `KeychainService.accessTokenKey` from Keychain; if present set `isAuthenticated = true` and load `userEmail` from `KeychainService.userEmailKey`

WHEN no token exists in Keychain on init
THEN `isAuthenticated = false`, `userEmail = nil`

---

### REQ-4: AuthService — register

**Scenarios:**

WHEN `register(email:password:)` is called with valid credentials
THEN POST `/api/auth/register` with `{ email, password }`; on 201 store `accessToken`, `refreshToken`, `email` in Keychain; set `isAuthenticated = true`, `userEmail = email`

WHEN the server returns 409
THEN throw an `ErrorInfo` with title "Email already in use"

WHEN the server returns any other error
THEN throw an `ErrorInfo` with title "Registration failed"

---

### REQ-5: AuthService — signIn

**Scenarios:**

WHEN `signIn(email:password:)` is called with correct credentials
THEN POST `/api/auth/login`; store tokens + email in Keychain; set `isAuthenticated = true`

WHEN the server returns 401
THEN throw an `ErrorInfo` with title "Incorrect email or password"

---

### REQ-6: AuthService — signOut

**Scenarios:**

WHEN `signOut()` is called
THEN POST `/api/auth/logout` with the current refresh token (best effort — do not throw if request fails)
AND delete `accessToken`, `refreshToken`, `userEmail` from Keychain
AND set `isAuthenticated = false`, `userEmail = nil`

---

### REQ-7: AuthService — refreshTokenIfNeeded

**Description:** Called silently on every `.active` scene phase. Swaps a near-expired access token without user interaction.

**Scenarios:**

WHEN access token has more than 60 seconds remaining
THEN do nothing

WHEN access token is within 60 seconds of expiry OR is already expired
THEN POST `/api/auth/refresh` with current refresh token; on success update `accessToken` + `refreshToken` in Keychain

WHEN refresh token is also expired or invalid (server returns 401)
THEN call `signOut()` (clear local state); do not throw to the caller

---

### REQ-8: NetworkClientProtocol — post method

**File:** `FocusOnYourself/Networking/NetworkClientProtocol.swift`

```swift
func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
```

**Scenarios:**

WHEN called with a valid path and encodable body
THEN construct URLRequest with method POST, `Content-Type: application/json`, encoded body
AND inject `Authorization: Bearer <token>` header if Keychain has a valid access token
AND apply identical response handling as `get` (200–299 decode, 304 cache, else throw)

WHEN body encoding fails
THEN throw `NetworkError.invalidURL` (re-use existing error type)
