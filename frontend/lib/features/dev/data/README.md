# features/dev/data

API client for the backend's dev-only demo-data endpoints
(`/api/v1/dev/**`), which `SecurityConfig` only permits when
`pickup.dev.enabled` is set (the `local`/`docker` profiles).

## Contents

- `dev_api.dart`
  - `DevApi.listAccounts()` — `GET /dev/accounts`: demo organizer accounts
    (`email`, `fullName`, `role`, `password`, defaulting to `test`).
  - `DevApi.seed()` — `POST /dev/seed`: seeds demo data, returning
    `DevSeedResponse` (`eventId`, `eventTitle`, `alreadyExisted`, `accounts`).
  - `devApiProvider` — `Provider<DevApi>`.
  - `devAccountsProvider` — `FutureProvider.autoDispose<List<DevAccountInfo>>`.

## How it connects

Used only by `features/auth/presentation/login_screen.dart`'s
`_DevTestingPanel`, and only rendered in `kDebugMode`. If the backend wasn't
started with dev endpoints enabled, `devAccountsProvider` errors and the
panel shows a message instead of the account list rather than failing hard.
