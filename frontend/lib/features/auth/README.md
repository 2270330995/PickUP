# features/auth

Organizer authentication: registration, login, session bootstrap/refresh, and
logout. There is only one kind of login in this app (the organizer) — see
"Organizer-first model" in the repo's `CLAUDE.md`.

## Subdirectories

- [`data/`](data/README.md) — `AuthApi`, hitting `/auth/register`,
  `/auth/login`, `/auth/refresh`, `/auth/logout`.
- [`presentation/`](presentation/README.md) — `LoginScreen` (with a
  debug-only demo-account panel backed by `features/dev`) and
  `RegisterScreen`.

Note: the actual session state machine (`AuthState`/`AuthController`) lives
in [`shared/providers/auth_provider.dart`](../../shared/providers/README.md),
not in this feature package, because `core/router`'s redirect logic and the
`core/network` 401 handler both need to depend on it without depending on a
specific feature.

## How it connects

`AuthController` bootstraps by attempting a refresh-token exchange on app
start; `core/router/app_router.dart`'s redirect uses its `AuthStatus` to
gate every route (loading -> splash, unauthenticated -> `/login`,
authenticated -> `/organizer`). Successful login/register writes tokens via
`core/storage` and the 401 interceptor in `core/network` calls
`AuthController._forceLogout` through `UnauthorizedNotifier`.
