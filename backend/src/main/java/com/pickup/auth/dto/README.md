# auth/dto

Request/response records for the auth endpoints.

## What's in it

- `RegisterRequest` — email, password, fullName, optional phone; all validated with
  Bean Validation annotations (`@Email`, `@NotBlank`, `@Size`).
- `LoginRequest` — email + password.
- `RefreshRequest` — a single `refreshToken` string.
- `AuthResponse` — the shape returned by register/login/refresh: `accessToken`,
  `refreshToken`, `expiresInSec`, and the caller's `UserResponse` (from
  `user/dto`).

## How it connects

Consumed by `AuthController` (validates `@RequestBody` payloads) and produced by
`AuthService`, which builds `AuthResponse` via `JwtTokenProvider` (`security/`) and
`UserMapper` (`user/`). These are plain records with no behavior; all logic lives in
the parent `auth/` package.
