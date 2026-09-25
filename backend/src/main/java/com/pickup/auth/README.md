# auth

Stateless JWT authentication endpoints for the single login kind in the app: the
organizer's `UserEntity` account (see "Organizer-first model" in the root
`CLAUDE.md` — Contacts never log in themselves).

## What's in it

- `AuthController` — `POST /api/v1/auth/register`, `/login`, `/refresh`, `/logout`.
  `logout` is a no-op (`204`); tokens are not tracked server-side.
- `AuthService` — registers a `UserEntity` (bcrypt-hashes the password, assigns
  `SystemRole.USER`), verifies login credentials, and reissues tokens on refresh
  by validating the refresh token's type/subject via `JwtTokenProvider`.
- [`dto/`](dto/README.md) — request/response records.

## How it connects

- Depends on `user/` (`UserEntity`, `UserRepository`, `UserMapper`) for the account
  record, `security/JwtTokenProvider` for token issuance/parsing, and
  `common/exception` (`ConflictException` on duplicate email,
  `UnauthorizedException` on bad credentials or an invalid refresh token).
- Every response is wrapped by the controller in `ApiResponse` (see
  `common/api/README.md`).
- `SecurityConfig` (`config/`) permits `/api/v1/auth/**` without authentication;
  everything else in the app requires the JWT this package issues.
