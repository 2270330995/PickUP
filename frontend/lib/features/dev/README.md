# features/dev

Thin client for the backend's local/docker-only demo-data endpoints. Not a
user-facing feature in production — it exists to make manual testing and
demos fast. This feature has no screens of its own.

## Subdirectories

- [`data/`](data/README.md) — `DevApi` (`listAccounts`, `seed`) and its DTOs.

## How it connects

Consumed only by the debug-only panel in
`features/auth/presentation/login_screen.dart`. Backed by
`/api/v1/dev/**`, which the backend only exposes when `pickup.dev.enabled`
is true (see the repo's `CLAUDE.md` "Commands" section).
