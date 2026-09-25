# features/auth/data

API client and DTOs for organizer login/registration/session refresh.

## Contents

- `auth_api.dart`
  - `AuthApi.register(RegisterRequest)` — `POST /auth/register`.
  - `AuthApi.login(LoginRequest)` — `POST /auth/login`.
  - `AuthApi.refresh(refreshToken)` — `POST /auth/refresh`.
  - `AuthApi.logout()` — `POST /auth/logout`, best-effort (failures are
    swallowed; tokens are always cleared client-side regardless).
  - `authApiProvider` — `Provider<AuthApi>` built on `dioProvider`.
- `auth_dtos.dart`
  - `RegisterRequest`, `LoginRequest` — request payloads.
  - `AuthResponse` — parses `{accessToken, refreshToken, expiresInSec, user}`,
    embedding a `UserResponse` (`features/user/data/user_dtos.dart`).

## How it connects

This is the only feature-data package that talks to `/api/v1/auth/**`, which
`SecurityConfig` on the backend permits without an authenticated principal.
Consumed exclusively by `shared/providers/auth_provider.dart`'s
`AuthController`, which stores the returned tokens via `TokenStorage`
(`core/storage`) and exposes auth state to `core/router`'s redirect logic.
Screens in `features/auth/presentation` never call `AuthApi` directly — they
go through `authProvider.notifier`.
