# Spec: backend-auth-api

## Overview

Five Express endpoints that handle user registration, login, token refresh, logout, and identity retrieval. All endpoints live under `/api/auth`. Tokens are JWTs signed with environment-variable secrets.

---

## Requirements

### REQ-1: POST /api/auth/register

**Description:** Creates a new user account. Returns access + refresh tokens on success.

**Request body:**
```json
{ "email": "user@example.com", "password": "mypassword" }
```

**Response (201):**
```json
{
  "accessToken": "<jwt>",
  "refreshToken": "<jwt>",
  "user": { "id": "clxxx", "email": "user@example.com" }
}
```

**Scenarios:**

WHEN email is already registered
THEN respond 409 `{ "error": "Email already in use" }`

WHEN email is missing or not a valid email format
THEN respond 400 `{ "error": "Invalid email" }`

WHEN password is fewer than 8 characters
THEN respond 400 `{ "error": "Password must be at least 8 characters" }`

WHEN request is valid
THEN hash password with bcrypt (cost 12), create User, store refresh token, respond 201

---

### REQ-2: POST /api/auth/login

**Description:** Authenticates an existing user. Returns access + refresh tokens on success.

**Request body:**
```json
{ "email": "user@example.com", "password": "mypassword" }
```

**Response (200):** same shape as register

**Scenarios:**

WHEN email is not found
THEN respond 401 `{ "error": "Invalid credentials" }` (do not reveal whether email exists)

WHEN password does not match
THEN respond 401 `{ "error": "Invalid credentials" }`

WHEN credentials are valid
THEN issue new access + refresh tokens, store refresh token, respond 200

---

### REQ-3: POST /api/auth/refresh

**Description:** Exchanges a valid refresh token for a new access token + rotated refresh token.

**Request body:**
```json
{ "refreshToken": "<jwt>" }
```

**Response (200):**
```json
{ "accessToken": "<jwt>", "refreshToken": "<jwt>" }
```

**Scenarios:**

WHEN refresh token is missing or not a string
THEN respond 400 `{ "error": "Refresh token required" }`

WHEN refresh token is not found in the database
THEN respond 401 `{ "error": "Invalid refresh token" }` (may have been rotated or logged out)

WHEN refresh token is expired
THEN delete it from DB; respond 401 `{ "error": "Refresh token expired" }`

WHEN refresh token is valid
THEN delete old token from DB, issue new access token + new refresh token, store new refresh token, respond 200

---

### REQ-4: POST /api/auth/logout

**Description:** Invalidates the current refresh token.

**Request body:**
```json
{ "refreshToken": "<jwt>" }
```

**Response (204):** no body

**Scenarios:**

WHEN refresh token is present and found in DB
THEN delete it; respond 204

WHEN refresh token is not found (already logged out or invalid)
THEN still respond 204 (idempotent)

---

### REQ-5: GET /api/auth/me

**Description:** Returns the authenticated user's identity. Protected by `authenticate` middleware.

**Headers:** `Authorization: Bearer <accessToken>`

**Response (200):**
```json
{ "id": "clxxx", "email": "user@example.com" }
```

**Scenarios:**

WHEN Authorization header is missing
THEN respond 401 `{ "error": "Authorization header required" }`

WHEN token is malformed or signature is invalid
THEN respond 401 `{ "error": "Invalid token" }`

WHEN token is expired
THEN respond 401 `{ "error": "Token expired" }`

WHEN token is valid
THEN respond 200 with `{ id, email }` of the authenticated user

---

### REQ-6: authenticate middleware

**Description:** Express middleware that validates a Bearer JWT and attaches `req.user` to the request.

**Signature:** `(req: Request, res: Response, next: NextFunction) => void`

**Scenarios:**

WHEN `Authorization` header is absent
THEN respond 401; do not call `next()`

WHEN header format is not `Bearer <token>`
THEN respond 401; do not call `next()`

WHEN `jwt.verify` throws `TokenExpiredError`
THEN respond 401 `{ "error": "Token expired" }`

WHEN `jwt.verify` succeeds
THEN set `req.user = { id: payload.sub }`; call `next()`
