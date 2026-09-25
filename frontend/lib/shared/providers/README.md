# shared/providers

Cross-feature Riverpod providers — state that multiple features depend on
and that can't live inside a single feature package without creating a
circular dependency.

## Contents

- `auth_provider.dart`
  - `AuthStatus` (`loading`, `unauthenticated`, `authenticated`) and
    `AuthState {status, user, errorMessage}`.
  - `AuthController extends StateNotifier<AuthState>`:
    - On construction, registers itself as the handler for
      `unauthorizedNotifierProvider` (`core/network`) and kicks off
      `_bootstrap()`, which exchanges a stored refresh token
      (`core/storage`) for a fresh session, or falls back to
      `unauthenticated`.
    - `login(email, password)` / `register(...)` — call
      `features/auth/data`'s `AuthApi`, persist tokens on success, update
      state; rethrow `ApiException` so the calling screen can show the
      error.
    - `signOut()` — calls `AuthApi.logout()` (best-effort) then clears
      local tokens.
    - `updateCachedUser(UserResponse)` — lets `features/profile` refresh the
      cached user without a full re-login.
    - `_forceLogout()` — the callback wired into `UnauthorizedNotifier`;
      fires synchronously from the dio 401 interceptor.
  - `authProvider` — `StateNotifierProvider<AuthController, AuthState>`.

## How it connects

Depends on `core/network` (dio, `UnauthorizedNotifier`), `core/storage`
(`TokenStorage`), `features/auth/data` (`AuthApi`), and
`features/user/data` (`UserResponse` type). Consumed by `core/router`'s
redirect logic, `features/auth/presentation` (login/register), and
`features/profile/presentation` (cache update + sign out). This provider —
not `features/auth`'s own package — is the source of truth for whether the
app considers the user logged in, because both `core/router` and
`core/network` need it without depending on a feature package.
