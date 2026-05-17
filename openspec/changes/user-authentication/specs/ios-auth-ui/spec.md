# Spec: ios-auth-ui

## Overview

Four new screens/views for the auth flow, all implemented from Pencil.dev designs using existing design-system tokens. No raw values — all spacing uses `Spacing.*`, all fonts use `.foy*` tokens, all colors use `Color.foy*`.

---

## Requirements

### REQ-1: AuthViewModel

**File:** `FocusOnYourself/Features/Auth/AuthViewModel.swift`

```swift
@Observable @MainActor
final class AuthViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var error: ErrorInfo?

    func signIn() async  // calls authService.signIn; sets error on failure
    func register() async  // validates confirmPassword match first; calls authService.register
}
```

**Scenarios:**

WHEN `register()` is called and `password != confirmPassword`
THEN set `error = ErrorInfo(title: "Passwords do not match")`; do not call the service

WHEN `signIn()` or `register()` succeeds
THEN `error = nil`; the sheet dismisses because `authService.isAuthenticated` becomes true

WHEN either throws
THEN set `error` from the thrown `ErrorInfo`; `isLoading` reset to false via `defer`

---

### REQ-2: SignInScreen

**File:** `FocusOnYourself/Features/Auth/SignInScreen.swift`

**Description:** Implements the Pencil.dev `SignInScreen` design. Canonical screen structure applies (`ZStack > foyBackground > VStack(0) > ScreenHeaderView + content`).

**Elements:**
- `ScreenHeaderView(title: "Sign In")`
- Email `TextField` — `.keyboardType(.emailAddress)`, `.textContentType(.emailAddress)`, `.autocapitalization(.never)`
- Password `SecureField` — `.textContentType(.password)`
- Sign In button — `FoyPrimaryButtonStyle`, disabled when either field is empty or `isLoading`
- "No account? Create one" link below button — tappable, switches to Sign Up tab in `AuthFlow`
- `InlineErrorView` when `viewModel.error != nil`

---

### REQ-3: SignUpScreen

**File:** `FocusOnYourself/Features/Auth/SignUpScreen.swift`

**Description:** Implements the Pencil.dev `SignUpScreen` design.

**Elements:**
- `ScreenHeaderView(title: "Create Account")`
- Email `TextField` — same content type config as SignInScreen
- Password `SecureField` — `.textContentType(.newPassword)`
- Confirm Password `SecureField` — `.textContentType(.newPassword)`
- Create Account button — `FoyPrimaryButtonStyle`, disabled when any field is empty or `isLoading`
- "Already have an account? Sign in" link — switches to Sign In tab
- `InlineErrorView` when `viewModel.error != nil`

---

### REQ-4: AuthFlow

**File:** `FocusOnYourself/Features/Auth/AuthFlow.swift`

**Description:** Sheet container that hosts Sign In and Sign Up with a segmented picker to switch between them. Implements the Pencil.dev `AuthFlow` design.

**Scenarios:**

WHEN `authService.isAuthenticated` becomes `true`
THEN dismiss the sheet (observe via `.onChange(of: authService.isAuthenticated)`)

**Structure:**
- `SheetDragHandle` at top
- Segmented `Picker` — "Sign In" / "Create Account"
- `SignInScreen` or `SignUpScreen` depending on picker selection
- Both screens share a single `AuthViewModel` instance owned by `AuthFlow`
- `presentationBackground(Color.foyBackground)`

---

### REQ-5: SettingsAccountSection

**File:** `FocusOnYourself/Features/Settings/Components/SettingsAccountSection.swift`

**Description:** Renders in two distinct states based on `viewModel.isAuthenticated`. Implements both Pencil.dev states from task 6.5.

**Signed-out state:**
- `SectionLabel("ACCOUNT")`
- Single card row: "Create account" text in `Color.foyNavy` + `chevron.right` icon
- Tapping sets `viewModel.showAuthFlow = true` → `.sheet` presenting `AuthFlow`

**Signed-in state:**
- `SectionLabel("ACCOUNT")`
- Email label row (non-tappable, `Color.foyForeground`)
- Divider
- "Sign Out" button row — `Color.red` text; on tap calls `viewModel.signOut()`
- Both rows in a single card (`.foyCardStyle()`)

**Scenarios:**

WHEN user taps "Create account" row
THEN `AuthFlow` sheet is presented

WHEN user taps "Sign Out"
THEN `viewModel.signOut()` is called; section transitions to signed-out state

WHEN `authService.isAuthenticated` changes
THEN section re-renders automatically (observable)
